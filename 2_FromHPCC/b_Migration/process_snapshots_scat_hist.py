import re
import os
import csv


generations = 10,2500,5000
population_size = 1000
is_from_group_index = 2
score_index = 4
scoreA_index = 5
scoreB_index = 6


def process_data(rep_dir, csv_processed, experiment, replicate):
    for gen in generations:
        with open(rep_dir + '/B__snapshot_data_' + str(gen) + '.csv', 'r') as read_obj:
            lod = csv.reader(read_obj)
            next(lod)  # skip header
            list_of_rows = list(lod)
            if len(list_of_rows) != population_size:
                print('ERROR at ' + rep_dir + '/B__snapshot_data_' + str(gen) + '.csv')
            else:
                match = re.search('MR_(.*)', experiment)
                mr = float(match.group(1))*100                
                for i in range(len(list_of_rows)):
                    if int(float(list_of_rows[i][is_from_group_index])) == 0:
                        csv_processed.writerow([int(mr), replicate, gen, int(float(list_of_rows[i][score_index])), int(float(list_of_rows[i][scoreA_index])), int(float(list_of_rows[i][scoreB_index])), 'Yes'])
                    elif int(float(list_of_rows[i][is_from_group_index])) == 1:
                        csv_processed.writerow([int(mr), replicate, gen, int(float(list_of_rows[i][score_index])), int(float(list_of_rows[i][scoreA_index])), int(float(list_of_rows[i][scoreB_index])), 'No'])



def main():
    curr_dir = './'
    all_exp_dirs = [dir for dir in os.listdir(curr_dir) if
                    os.path.isdir(os.path.join(curr_dir, dir)) and dir.startswith('MIGRATION_SCAT_HIST')]
    with open('migration_snapshots_scat_hist_unsorted.csv', 'w', newline='') as processed_csv:
        # write csv-header
        csv_processed = csv.writer(processed_csv)
        csv_processed.writerow(
            ['migration_rate', 'replicate', 'update', 'score', 'scoreA', 'scoreB', 'migrated']) # migrated = isFromGroup in flipped order (0=True, 1=False)

        # loop through all B__snapshot_data_x.csv
        for experiment in all_exp_dirs:
            exp_dir = curr_dir + experiment + '/'
            replicates = [rep for rep in os.listdir(exp_dir) if os.path.isdir(os.path.join(exp_dir))]
            for replicate in replicates:
                rep_dir = exp_dir + replicate + '/'
                process_data(rep_dir, csv_processed, experiment, replicate)
    with open('migration_snapshots_scat_hist_unsorted.csv', 'r') as read_obj, open('migration_scat_hist_snapshots.csv', 'w', newline='') as write_obj:
        us = csv.reader(read_obj)
        header = next(us, None)
        s = csv.writer(write_obj)
        if header:
            s.writerow(header)
        s.writerows(sorted(us, key=lambda x: (float(x[0]),x[1],int(x[2]))))
        if os.path.exists('migration_snapshots_scat_hist_unsorted.csv'):
          os.remove('migration_snapshots_scat_hist_unsorted.csv')
        else:
          print('File does not exist.')

if __name__ == "__main__":
    main()

