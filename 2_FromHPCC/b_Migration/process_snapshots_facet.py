import re
import os
import csv
import numpy as np
import pandas as pd


generations = 5000
population_size = 1000
score_index = 4
scoreA_index = 5
scoreB_index = 6


def process_data(rep_dir, csv_processed, experiment, replicate):
    for gen in range(generations+1):
        df = pd.read_csv(rep_dir + '/B__snapshot_data_' + str(gen) + '.csv')

        if len(df) != population_size:
            print('ERROR at ' + rep_dir + '/B__snapshot_data_' + str(gen) + '.csv')
        else:
            match = re.search('MR_(.*)', experiment)
            mr = float(match.group(1))*100

            a_score = df["scoreA"]
            a_score = np.digitize(a_score, [20,40,60,80])
            a_score = a_score.tolist()

            b_score = df["scoreB_AVE"]
            b_score = np.digitize(b_score, [20,40,60,80])
            b_score = b_score.tolist()

            org_score = df["score"]
            org_score = np.digitize(org_score, [20,40,60,80])
            org_score = org_score.tolist()

            csv_processed.writerow([int(mr), replicate, gen, "0-20", a_score.count(0), b_score.count(0), org_score.count(0)])
            csv_processed.writerow([int(mr), replicate, gen, "20-40", a_score.count(1), b_score.count(1), org_score.count(1)])
            csv_processed.writerow([int(mr), replicate, gen, "40-60", a_score.count(2), b_score.count(2), org_score.count(2)])
            csv_processed.writerow([int(mr), replicate, gen, "60-80", a_score.count(3), b_score.count(3), org_score.count(3)])
            csv_processed.writerow([int(mr), replicate, gen, "80-100", a_score.count(4), b_score.count(4), org_score.count(4)])


def main():
    replicate_counter = 0
    curr_dir = './'
    all_exp_dirs = [dir for dir in os.listdir(curr_dir) if
                    os.path.isdir(os.path.join(curr_dir, dir)) and dir.startswith('MIGRATION_FACET')]
    with open('migration_facet_snapshots_unsorted.csv', 'w', newline='') as processed_csv:
        # write csv-header
        csv_processed = csv.writer(processed_csv)
        csv_processed.writerow(
            ['migration_rate', 'replicate', 'update', 'bin', 'a_count', 'b_count', 'org_count'])

        # loop through all B__snapshot_data_x.csv
        for experiment in all_exp_dirs:
            exp_dir = curr_dir + experiment + '/'
            replicates = [rep for rep in os.listdir(exp_dir) if os.path.isdir(os.path.join(exp_dir))]
            for replicate in replicates:
                rep_dir = exp_dir + replicate + '/'
                process_data(rep_dir, csv_processed, experiment, replicate)
                print("Finished replicates: ", replicate_counter)
                replicate_counter += 1      
    with open('migration_facet_snapshots_unsorted.csv', 'r') as read_obj, open('migration_facet_snapshots.csv', 'w', newline='') as write_obj:
        us = csv.reader(read_obj)
        header = next(us, None)
        s = csv.writer(write_obj)
        if header:
            s.writerow(header)
        s.writerows(sorted(us, key=lambda x: (float(x[0]),x[1],int(x[2]))))
        if os.path.exists('migration_facet_snapshots_unsorted.csv'):
          os.remove('migration_facet_snapshots_unsorted.csv')
        else:
          print('File does not exist.')

if __name__ == "__main__":
    main()

