import os
import subprocess

def response(start_response, status, message):
   response_status = status
   response_body = message
   response_headers = [('Content-Length', str(len(response_body)))]
   
   start_response(response_status, response_headers)
   return [response_body];

def application(env, start_response):
    path = env['PATH_INFO'].split(os.sep)
    request_type = path[1]
    if not request_type:
        return response(start_response, '400 Bad Request', 'No request type specified!')

    if request_type == 'renewability':
        # Get the path to the renewability script and validate it
        rs_path = os.path.join(os.sep, *path[2:-1])
        name = os.path.basename(rs_path)
        if not name.startswith('generate_') or not name.endswith('.sh'):
            return response(start_response, '400 Bad Request', 'Invalid renewability script requested.')

        # Get the seed and validate it
        seed = path[-1]
        if not seed.isdigit():
            return response(start_response, '400 Bad Request', 'Invalid seed for renewability script.')

        # Execute the script, and check its return code
        if subprocess.call([rs_path, seed]):
            return response(start_response, '500 Internal Server Error', 'Renewability script did not execute successfully.')

        return response(start_response, '200 OK', 'Script successfully executed.')
    else:
        return response(start_response, '400 Bad Request', 'Unknown request type.')
