#!/usr/bin/python3
import concurrent.futures
import os
import shutil
import subprocess
import sys

# Import own modules
import reporting

# Paths
framework_dir = os.path.abspath(os.path.dirname(sys.argv[0]))
docker_script = os.path.join(framework_dir, 'docker', 'run.sh')
rel_data_dir = os.path.join('projects', 'data')
data_dir_on_system = os.path.join(framework_dir, rel_data_dir)
data_dir_in_docker = os.path.join('/', rel_data_dir)

# Experiment parameters
number_of_seeds = 20
transformation_types = ['FPReordering', 'StructReordering']
numbers_of_versions = [2, 5, 10, 20, 50, 100]

def run_base_experiment(output_dir, with_cm):
    mode = '-2' if with_cm else '-1'
    subprocess.check_call([docker_script, '--mode', mode, '--output_dir', output_dir], env={'DEMO_PROJECTS' : 'no'}, stdout=subprocess.DEVNULL)

def run_SR_experiment(output_dir, transformation_type, number_of_versions, seed):
    subprocess.check_call([docker_script, '--mode', '2', '--numbers_of_versions', str(number_of_versions), '--output_dir', output_dir,
        '--seed', str(seed), '--transformation_type', transformation_type], env={'DEMO_PROJECTS' : 'no'}, stdout=subprocess.DEVNULL)

def main():
    # Prepare docker
    subprocess.check_call(['docker-compose', 'up', '-d'])

    with concurrent.futures.ProcessPoolExecutor() as executor:
        # Run all base experiments
        executor.submit(run_base_experiment, os.path.join(data_dir_in_docker, 'base_with_cm'), True)
        executor.submit(run_base_experiment, os.path.join(data_dir_in_docker, 'base_without_cm'), False)

        # Run all SR experiments
        for transformation_type in transformation_types:
            for number_of_versions in numbers_of_versions:
                for seed in range(number_of_seeds):
                    output_dir = os.path.join(data_dir_in_docker, transformation_type, str(number_of_versions), str(seed))
                    executor.submit(run_SR_experiment, output_dir, transformation_type, number_of_versions, seed)

    # Gather data
    reporting.main(data_dir_on_system, number_of_seeds, transformation_types, numbers_of_versions)

if __name__ == '__main__':
    main()
