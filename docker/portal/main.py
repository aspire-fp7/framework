import json
from subprocess import Popen, PIPE

ACCL_TID_CODE_SPLITTING = 10
ACCL_TID_CODE_MOBILITY = 20
ACCL_TID_DATA_MOBILITY = 21
ACCL_TID_WBS = 30
ACCL_TID_MTC_CRYPTO_SERVER = 40
ACCL_TID_DIVERSIFIED_CRYPTO = 41
ACCL_TID_CG_HASH_RANDOMIZATION = 50
ACCL_TID_CG_HASH_VERIFICATION = 55
ACCL_TID_CFGT_REMOVE_VERIFIER = 60
ACCL_TID_AC_DECISION_LOGIC = 70
ACCL_TID_AC_STATUS_LOGIC = 75
ACCL_TID_RA_REACTION_MANAGER = 80
ACCL_TID_TEST = 9999

def error_response(start_response, message):
   response_status = '500 KO'
   response_body = message
   response_headers = [('Content-Length', str(len(response_body)))]
   
   start_response(response_status, response_headers)
   
   return [response_body];

def success_response(start_response, response):
   response_status = '200 OK'
   response_body = response
   response_headers = [('Content-Type', 'application/octet-stream'),
                       ('Content-Length', str(len(response)))]
   
   start_response(response_status, response_headers)
   
   return [response_body];

def application(environ, start_response):
   # the environment variable CONTENT_LENGTH may be empty or missing
   try:
      request_body_size = int(environ.get('CONTENT_LENGTH', 0))
   except (ValueError):
      request_body_size = 0

   if request_body_size == 0:
      return error_response(start_response, 'payload size error')

   error = 0
   response_headers = []
   response_body = ''
   
   # first element of the path is the Technique ID
   path = environ['PATH_INFO'].split('/')

   # if an element was provided
   if (len(path) > 3):
      try:
         # read the request type
         request_type = path[1]
         
         # read the technique id
         technique_id = path[2]

         # read the application id
         application_id = path[3]
         
         # load techniques definition JSON file
         backends_file = open('/app/backends.json')
         backends = json.load(backends_file)
        
         if request_type != 'exchange' and request_type != 'send':
            return error_response(start_response, 'invalid request type');
         
         if not backends.has_key(str(technique_id)):
            return error_response(start_response, 'invalid technique ' 
            	+ str(technique_id));

         # read POSTed data (payload)
         request_body = environ['wsgi.input'].read(request_body_size)
      
         # read the name of backend service
         technique_backend = backends[technique_id][request_type];
         
         # launch backend service passing the payload size as first param
         process_res = Popen([technique_backend, 
         				request_type,
         				str(len(request_body)),
         				application_id],
                        stdout=PIPE,
                        stdin=PIPE)
         
         # send the buffer to the backend service
         out, err = process_res.communicate(request_body)
         
         if process_res.returncode == 0:
            return success_response(start_response, out)
         
         return error_response(start_response, 'technique backend failed')
      except Exception as err:
         return error_response(start_response, err.message)
   else:
      return error_response(start_response, 'invalid arguments')

   return error_response(start_response, 'unknown')
