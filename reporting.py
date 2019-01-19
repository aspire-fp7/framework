#!/usr/bin/python3
import json
import os
import pyexcel
import subprocess
import tempfile

def hex_int(x):
    return int(x, 16)

def get_binary_stripped_size(binary, tmp_dir):
    if os.path.exists(binary):
        output = os.path.join(tmp_dir, 'binary')
        subprocess.check_output(['strip', '--input-target', 'elf32-little', '-o', output, binary])
        return os.stat(output).st_size
    else:
        return 'FAIL'

def get_binary_text_size(binary):
    if os.path.exists(binary):
        for line in subprocess.check_output(['objdump', '-h', binary], universal_newlines=True).splitlines():
            tokens = line.split()
            if len(tokens) >= 3 and tokens[1] == '.text':
                return hex_int(tokens[2])
    else:
        return 'FAIL'

def get_number_of_annotations(annotations_file):
    if os.path.exists(annotations_file):
        with open(annotations_file, 'r') as f:
            data = json.load(f)
        return len(data)
    else:
        return 'FAIL'

def get_total_mobile_block_size(mobile_blocks_dir):
    dirs = [filename for filename in os.listdir(mobile_blocks_dir) if not filename.startswith('.')]
    if len(dirs) != 1:
        return 'FAIL'

    timestamp_dir = os.path.join(mobile_blocks_dir, dirs[0])
    block_sizes = [os.stat(os.path.join(timestamp_dir, filename)).st_size for filename in os.listdir(timestamp_dir) if not filename.endswith('.metadata')]
    return sum(block_sizes)

def main(data_dir, number_of_seeds, transformation_types, numbers_of_versions):
    with tempfile.TemporaryDirectory() as tmp_dir:
        # Get base measurements
        binary = os.path.join(data_dir, 'base_with_cm', 'actc', 'build', 'base', 'BC05', 'bzip2')
        base_with_cm_binary_size_stripped = get_binary_stripped_size(binary, tmp_dir)
        base_with_cm_binary_text_size = get_binary_text_size(binary)
        binary = os.path.join(data_dir, 'base_without_cm', 'actc', 'build', 'base', 'BC05', 'bzip2')
        base_without_cm_binary_size_stripped = get_binary_stripped_size(binary, tmp_dir)
        base_without_cm_binary_text_size = get_binary_text_size(binary)
        extra_cm_text_size = base_with_cm_binary_text_size - base_without_cm_binary_text_size

        for transformation_type in transformation_types:
            # Create a sheets dictionary, we will add a sheet for every number of versions
            sheets = {}

            # Create an overview sheet
            overview_sheet = pyexcel.Sheet(name='Overview')
            sheets['Overview'] = overview_sheet
            overview_sheet.row += ['Number of versions', 'Binary Size (stripped)', 'Binary Text Size', 'Number Of Annotations',
                    'AVG Total Mobile Block Size', 'MAX Total Mobile Block Size', '', 'Mobile To Base Text Size', 'Text Size to CM Support Text Size', 'Base Text Left']

            for number_of_versions in numbers_of_versions:
                # Create the sheet for this number of versions and put it in the dictionary
                sheet = pyexcel.Sheet(name=str(number_of_versions))
                sheets[str(number_of_versions)] = sheet
                binary_sizes_stripped = ['Binary Size (stripped)']
                binary_text_sizes = ['Binary Text Size']
                numbers_of_annotations = ['Number Of Annotations']
                avg_total_mobile_block_sizes = ['AVG Total Mobile Block Size']
                max_total_mobile_block_sizes = ['MAX Total Mobile Block Size']

                for seed in range(number_of_seeds):
                    # The directory for this specific run
                    run_dir = os.path.join(data_dir, transformation_type, str(number_of_versions), str(seed))

                    # For this run, calculate: binary stripped size, binary .text size, number of annotations, and avg/max total mobile block size
                    actc_build_dir = os.path.join(run_dir, 'actc', 'build')
                    binary = os.path.join(actc_build_dir, 'version_v1', 'BC05', 'bzip2')
                    binary_sizes_stripped.append(get_binary_stripped_size(binary, tmp_dir))
                    binary_text_sizes.append(get_binary_text_size(binary))
                    numbers_of_annotations.append(get_number_of_annotations(os.path.join(run_dir, 'actc', 'annotations.out')))
                    total_mobile_block_sizes = []
                    for version in range(1, number_of_versions +1):
                        total_mobile_block_sizes.append(get_total_mobile_block_size(os.path.join(actc_build_dir, 'version_v' + str(version), 'BC05', 'mobile_blocks')))
                    actual_sizes = [elem for elem in total_mobile_block_sizes if isinstance(elem, int)]
                    avg_total_mobile_block_sizes.append(sum(actual_sizes) // len(actual_sizes))
                    max_total_mobile_block_sizes.append(max(actual_sizes))

                average_row = [str(number_of_versions)]
                for column in [binary_sizes_stripped, binary_text_sizes, numbers_of_annotations, avg_total_mobile_block_sizes, max_total_mobile_block_sizes]:
                    numbers = [elem for elem in column if isinstance(elem, int)]
                    column.append(sum(numbers) // len(numbers))
                    average_row.append(sum(numbers) // len(numbers))
                    column.append(max(numbers))
                    sheet.column += column

                average_row.append('')
                average_row.append(average_row[4] / base_without_cm_binary_text_size)
                average_row.append(average_row[2] / (extra_cm_text_size))
                average_row.append((average_row[2] - extra_cm_text_size) / base_without_cm_binary_text_size)
                overview_sheet.row += average_row

            # Create the report book for the transformation type and write it out
            report = pyexcel.Book(sheets=sheets)
            report.save_as(transformation_type + '.ods')
