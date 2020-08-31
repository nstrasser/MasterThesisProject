import re
import os
import csv


generations = 5000
score_index = 1
scoreA_index = 2
scoreB_index = 3
update_index = 4


def process_data(rep_dir, csv_processed, experiment, replicate):
    with open(rep_dir + '/A__pop.csv', 'r') as read_obj:
        lod = csv.reader(read_obj)
        next(lod)  # skip header
        list_of_rows = list(lod)
        if len(list_of_rows) != generations+1:
            print('ERROR at ' + rep_dir + '/' + a_or_b + '__pop.csv')
        else:
            match = re.search('MR_(.*)', experiment)
            mr = float(match.group(1))*100
            for i in range(len(list_of_rows)-1):
                csv_processed.writerow([int(mr), replicate, 'Organism', list_of_rows[i][score_index], list_of_rows[i][update_index]])
                csv_processed.writerow([int(mr), replicate, 'A', list_of_rows[i][scoreA_index], list_of_rows[i][update_index]])
                csv_processed.writerow([int(mr), replicate, 'B', list_of_rows[i][scoreB_index], list_of_rows[i][update_index]])



def main():
    curr_dir = './'
    all_exp_dirs = [dir for dir in os.listdir(curr_dir) if
                    os.path.isdir(os.path.join(curr_dir, dir)) and dir.startswith('MIGRATION_LINE_CHART')]
    with open('migration_line_chart_pop_unsorted.csv', 'w', newline='') as processed_csv:
        # write csv-header
        csv_processed = csv.writer(processed_csv)
        csv_processed.writerow(
            ['migration_rate', 'replicate', 'type', 'score', 'update'])

        # loop through all A_pop.csv (B_pop.csv are equal and it is not necessary to loop them too)
        for experiment in all_exp_dirs:
            exp_dir = curr_dir + experiment + '/'
            replicates = [rep for rep in os.listdir(exp_dir) if os.path.isdir(os.path.join(exp_dir))]
            for replicate in replicates:
                rep_dir = exp_dir + replicate + '/'
                process_data(rep_dir, csv_processed, experiment, replicate)
    with open('migration_line_chart_pop_unsorted.csv', 'r') as read_obj, open('migration_line_chart_pop.csv', 'w', newline='') as write_obj:
        us = csv.reader(read_obj)
        header = next(us, None)
        s = csv.writer(write_obj)
        if header:
            s.writerow(header)
        s.writerows(sorted(us, key=lambda x: (float(x[0]),x[1], int(x[4]))))
        if os.path.exists('migration_line_chart_pop_unsorted.csv'):
          os.remove('migration_line_chart_pop_unsorted.csv')
        else:
          print('File does not exist.')

if __name__ == "__main__":
    main()

