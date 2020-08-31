
import os
import csv


generations = 5000
update_index = 0
genome_index = 4
genome_score_index = 5
org_score_index = 7


def generate_mutation_string(list_of_rows):
    overall_mutations = ''
    leading_one_mutations = ''
    for i in range(len(list_of_rows)-1):
        row = list_of_rows[i]
        next_row = list_of_rows[i+1]
        if row[genome_index] == next_row[genome_index]:
            overall_mutations += 'o'
            leading_one_mutations += 'o'
        else:
            # overall mutations
            if row[genome_score_index] > next_row[genome_score_index]:  # - ... current > successor
                overall_mutations += '-'
            elif row[genome_score_index] < next_row[genome_score_index]:  # + ... current < successor
                overall_mutations += '+'
            else:  # s ... current = successor (in terms of score but genomes are different)
                overall_mutations += 's'

            # leading-one mutations
            if len(row[genome_index].split('0', 1)[0]) > len(next_row[genome_index].split('0', 1)[0]):
                leading_one_mutations += '-'
            elif len(row[genome_index].split('0', 1)[0]) < len(next_row[genome_index].split('0', 1)[0]):
                leading_one_mutations += '+'
            elif len(row[genome_index].split('0', 1)[0]) == len(next_row[genome_index].split('0', 1)[0]):
                leading_one_mutations += 'o'
            else:  # should never occur
                leading_one_mutations += 's'
    return leading_one_mutations, overall_mutations


def get_fitness(list_of_rows):
    fitness_score = -1000
    fitness_score_cell = list_of_rows[-1][genome_score_index]
    fitness_score_organism = list_of_rows[-1][org_score_index]
    return fitness_score_cell, fitness_score_organism


def process_lod_data(rep_dir, a_or_b, csv_processed, experiment, replicate):
    with open(rep_dir + '/' + a_or_b + '__LOD_data.csv', 'r') as read_obj:
        lod = csv.reader(read_obj)
        next(lod)  # skip header
        list_of_rows = list(lod)
        if len(list_of_rows) != generations+1:
            print('ERROR at ' + rep_dir + '/' + a_or_b + '__LOD_data.csv')
        else:
            leading_one_mutations, overall_mutations = generate_mutation_string(list_of_rows)
            fitness_score_cell, fitness_score_organism = get_fitness(list_of_rows)
            csv_processed.writerow([experiment, replicate, a_or_b, fitness_score_cell, fitness_score_organism, overall_mutations, leading_one_mutations])


def main():
    curr_dir = './'
    all_exp_dirs = [dir for dir in os.listdir(curr_dir) if
                    os.path.isdir(os.path.join(curr_dir, dir)) and dir.startswith('DIF')]  # or 'CONFIG'
    with open('final_processed_data_different_mutation_rates_unsorted.csv', 'w', newline='') as processed_csv: # or 'equal'
        # write csv-header
        csv_processed = csv.writer(processed_csv)
        csv_processed.writerow(
            ['experiment', 'replicate', 'cell', 'fitness_score_cell', 'fitness_score_organism', 'overall_mutations', 'leading_one_mutations'])

        # loop through all A_LOD.csv and B_LOD.csv
        for experiment in all_exp_dirs:
            exp_dir = curr_dir + experiment + '/'
            replicates = [rep for rep in os.listdir(exp_dir) if os.path.isdir(os.path.join(exp_dir))]
            for replicate in replicates:
                rep_dir = exp_dir + replicate + '/'
                process_lod_data(rep_dir, 'A', csv_processed, experiment, replicate)
                process_lod_data(rep_dir, 'B', csv_processed, experiment, replicate)
    with open('final_processed_data_different_mutation_rates_unsorted.csv', 'r') as read_obj, open('final_processed_data_different_mutation_rates.csv', 'w', newline='') as write_obj:    # or 'equal' and 'equal'
        us = csv.reader(read_obj)
        header = next(us, None)
        s = csv.writer(write_obj)
        if header:
            s.writerow(header)
        s.writerows(sorted(us, key=lambda x: (int(x[1]),x[2])))
        if os.path.exists('final_processed_data_different_mutation_rates_unsorted.csv'):    # or 'equal'
          os.remove('final_processed_data_different_mutation_rates_unsorted.csv')   # or 'equal'
        else:
          print('File does not exist.')

if __name__ == "__main__":
    main()

