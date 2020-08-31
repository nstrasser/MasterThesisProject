import csv
import itertools
import random
import re
import statistics

import pandas as pd

intra_run_reps = 50
inter_run_reps = 100
inter_treatment_reps = 100


def compute_amm(genome_a, genome_b):
    chunk_size = 100
    differentials = []
    if len(genome_a) == len(genome_b):
        for i in range(0, len(genome_a), chunk_size):
            beneficial_mut_a = genome_a[i:i + chunk_size].count('+')
            beneficial_mut_b = genome_b[i:i + chunk_size].count('+')
            differentials.append(beneficial_mut_a - beneficial_mut_b)
    return statistics.variance(differentials)


def count_mutations(mutation_string):
    b = mutation_string.count('+')  # fitness plus
    d = mutation_string.count('-')  # fitness minus
    s = mutation_string.count('s')  # neutral regarding fitness; silent since genome is different but fitness is same
    n = mutation_string.count('o')  # no mutation at all; genome is the same
    return b, d, s, n


def pop_random(lst):
    index = random.randrange(0, len(lst))
    return lst.pop(index)


def generate_csv_files(file_name):
    path = '../2_FromHPCC/a_Genetic_Signature/' + file_name
    file_prefix_match = re.search('data_(.*)_mutation', file_name)
    file_prefix = file_prefix_match.group(1)

    print(file_name)

    df = pd.read_csv(path)

    # open all csv-files
    with open(file_prefix + '_mutation_count.csv', 'w', newline='') as mutation_count_csv, \
            open(file_prefix + '_fitness_score.csv', 'w', newline='') as fitness_score_csv, \
            open(file_prefix + '_mutation_type.csv', 'w', newline='') as mutation_type_csv, \
            open(file_prefix + '_amm_heatmaps.csv', 'w', newline='') as amm_heatmaps_csv, \
            open(file_prefix + '_amm.csv', 'w', newline='') as amm_csv, \
            open(file_prefix + '_amm_switched_pairs.csv', 'w', newline='') as amm_switched_pairs_csv:

        # insert headers to all csv-files
        # intra-run comparison only
        csv_mutation_count = csv.writer(mutation_count_csv)
        csv_mutation_count.writerow(
            ['configuration', 'pop_mut', 'scenario', 'mutation_rate', 'population_size', 'replicate_seed', 'cell',
             'value_leading_ben_del_neu', 'value_leading_ben_del_neu_no', 'value_overall_ben_del_neu',
             'value_overall_ben_del_neu_no'])

        # intra-run comparison only
        csv_fitness_score = csv.writer(fitness_score_csv)
        csv_fitness_score.writerow(
            ['configuration', 'pop_mut', 'scenario', 'mutation_rate', 'population_size', 'replicate_seed', 'cell',
             'fitness_value_cell', 'fitness_value_organism'])

        # intra-run comparison only
        csv_mutation_type = csv.writer(mutation_type_csv)
        csv_mutation_type.writerow(
            ['configuration', 'pop_mut', 'scenario', 'mutation_rate', 'population_size', 'replicate_seed', 'cell',
             'type', 'value_leading', 'value_overall', 'fraction_leading_ben_del_neu', 'fraction_overall_ben_del_neu',
             'fraction_leading_ben_del_neu_no', 'fraction_overall_ben_del_neu_no'])

        # intra-run comparison only
        csv_amm_heatmaps = csv.writer(amm_heatmaps_csv)
        csv_amm_heatmaps.writerow(
            ['configuration', 'pop_mut', 'scenario', 'mutation_rate_a', 'mutation_rate_b', 'population_size',
             'a_replicate', 'b_replicate', 'variance_leading', 'variance_overall'])

        # intra-run, inter-run and inter-treatment
        csv_amm = csv.writer(amm_csv)
        csv_amm.writerow(
            ['configuration', 'pop_mut', 'scenario', 'mutation_rate_a', 'mutation_rate_b', 'population_size',
             'comparison', 'a_replicate', 'b_replicate', 'variance_leading', 'variance_overall'])

        # intra-run, inter-run and inter-treatment
        csv_amm_switched_pairs = csv.writer(amm_switched_pairs_csv)
        csv_amm_switched_pairs.writerow(
            ['configuration', 'pop_mut', 'scenario', 'mutation_rate_a', 'mutation_rate_b', 'population_size',
             'comparison', 'a_replicate', 'b_replicate', 'variance_leading', 'variance_overall'])

        # initialize indices
        start_index = 0
        end_index = start_index + (intra_run_reps * 2)

        # global match patterns needed for regex
        match_pattern_scenario = '(.*)__IP_(.*)__C.*SC_(.*)__MA_(.*)__.*_(.*)'  # match.group(1) ... CONFIG/DIFF_MUT
                                                                                # match.group(2) ... population size
                                                                                # match.group(3) ... scenario
                                                                                # match.group(4) ... mutation rate a (MA)
                                                                                # match.group(5) ... mutation rate b (MB)
        match_pattern_drift = '(.*)_DRIFT__IP_(.*)__C.*SC_(.*)__MA_(.*)__.*_(.*)'

        # start loop
        # WARNING: not optimized code, code increased over time, messy iterative approach, code duplication!
        while end_index < len(df):
            # do intra-run comparisons
            current_df = df[start_index:end_index]
            current_rep = current_df.loc[start_index]['replicate']

            categories = [i for i in (list(range(current_rep, current_rep + intra_run_reps)))]
            all_combinations = list(itertools.product(categories, categories))
            all_combinations_list = [list(elem) for elem in all_combinations]

            for elem in all_combinations_list:
                match_first_elem = current_df.loc[df['replicate'] == elem[0]]
                match_second_elem = current_df.loc[df['replicate'] == elem[1]]

                # process all combinations for amm_heatmaps.csv
                match = re.search(match_pattern_scenario, match_first_elem.iloc[0]['experiment'])
                pop_mut = match.group(2) + ', ' + match.group(4) + ', ' + match.group(5)
                variance_leading = compute_amm(match_first_elem.iloc[0]['leading_one_mutations'],
                                               match_second_elem.iloc[1]['leading_one_mutations'])
                variance_overall = compute_amm(match_first_elem.iloc[0]['overall_mutations'],
                                               match_second_elem.iloc[1]['overall_mutations'])
                csv_amm_heatmaps.writerow(
                    [match.group(1), pop_mut, match.group(3), match.group(4), match.group(5), match.group(2), elem[0],
                     elem[1], variance_leading, variance_overall])

                # only process 101 with 101 and so on combinations for all other csv-files
                if elem[0] == elem[1]:
                    csv_amm.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(5), match.group(2),
                         'intra-run', elem[0], elem[1], variance_leading, variance_overall])

                    # process data for mutation_count.csv, fitness_score.csv and mutation_type.csv
                    # for A-cell
                    beneficial_leading, deleterious_leading, neutral_leading, no_mutation_leading = count_mutations(
                        match_first_elem.iloc[0]['leading_one_mutations'])
                    beneficial_overall, deleterious_overall, neutral_overall, no_mutation_overall = count_mutations(
                        match_first_elem.iloc[0]['overall_mutations'])

                    ben_del_neu_no_leading_all = beneficial_leading + deleterious_leading + \
                                                        neutral_leading + no_mutation_leading
                    ben_del_neu_no_overall_all = beneficial_overall + deleterious_overall + \
                                                        neutral_overall + no_mutation_overall

                    ben_del_neu_leading_all = beneficial_leading + deleterious_leading + neutral_leading
                    ben_del_neu_overall_all = beneficial_overall + deleterious_overall + neutral_overall

                    # mutation_count.csv
                    csv_mutation_count.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(2),
                         match_first_elem.iloc[0]['replicate'], match_first_elem.iloc[0]['cell'],
                         ben_del_neu_leading_all, ben_del_neu_no_leading_all,
                         ben_del_neu_overall_all, ben_del_neu_no_overall_all])

                    # fitness_score.csv
                    csv_fitness_score.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(2),
                         match_first_elem.iloc[0]['replicate'], match_first_elem.iloc[0]['cell'],
                         match_first_elem.iloc[0]['fitness_score_cell'], match_first_elem.iloc[0]['fitness_score_organism']])

                    # mutation_type.csv
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(2),
                         match_first_elem.iloc[0]['replicate'],
                         match_first_elem.iloc[0]['cell'], 'beneficial', beneficial_leading, beneficial_overall,
                         ((beneficial_leading / ben_del_neu_leading_all) if ben_del_neu_leading_all > 0 else 0),
                         ((beneficial_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         ((beneficial_leading / ben_del_neu_no_leading_all) if ben_del_neu_no_leading_all > 0 else 0),
                         ((beneficial_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(2),
                         match_first_elem.iloc[0]['replicate'],
                         match_first_elem.iloc[0]['cell'], 'deleterious', deleterious_leading, deleterious_overall,
                         ((deleterious_leading / ben_del_neu_leading_all) if ben_del_neu_leading_all > 0 else 0),
                         ((deleterious_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         ((deleterious_leading / ben_del_neu_no_leading_all) if ben_del_neu_no_leading_all > 0 else 0),
                         ((deleterious_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(2),
                         match_first_elem.iloc[0]['replicate'],
                         match_first_elem.iloc[0]['cell'], 'neutral', neutral_leading, neutral_overall,
                         ((neutral_leading / ben_del_neu_leading_all) if ben_del_neu_leading_all > 0 else 0),
                         ((neutral_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         ((neutral_leading / ben_del_neu_no_leading_all) if ben_del_neu_no_leading_all > 0 else 0),
                         ((neutral_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(4), match.group(2),
                         match_first_elem.iloc[0]['replicate'],
                         match_first_elem.iloc[0]['cell'], 'no_mutation', no_mutation_leading, no_mutation_overall,
                         0, ((beneficial_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         0, ((no_mutation_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])


                    # for B-cell
                    beneficial_leading, deleterious_leading, neutral_leading, no_mutation_leading = count_mutations(
                        match_first_elem.iloc[1]['leading_one_mutations'])
                    beneficial_overall, deleterious_overall, neutral_overall, no_mutation_overall = count_mutations(
                        match_first_elem.iloc[1]['overall_mutations'])

                    ben_del_neu_no_leading_all = beneficial_leading + deleterious_leading + \
                                                        neutral_leading + no_mutation_leading
                    ben_del_neu_no_overall_all = beneficial_overall + deleterious_overall + \
                                                        neutral_overall + no_mutation_overall

                    ben_del_neu_leading_all = beneficial_leading + deleterious_leading + neutral_leading
                    ben_del_neu_overall_all = beneficial_overall + deleterious_overall + neutral_overall

                    # mutation_count.csv
                    csv_mutation_count.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(5), match.group(2),
                         match_first_elem.iloc[1]['replicate'], match_first_elem.iloc[1]['cell'],
                         ben_del_neu_leading_all, ben_del_neu_no_leading_all,
                         ben_del_neu_overall_all, ben_del_neu_no_overall_all])

                    # fitness_score.csv
                    csv_fitness_score.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(5), match.group(2),
                         match_first_elem.iloc[1]['replicate'], match_first_elem.iloc[1]['cell'],
                         match_first_elem.iloc[1]['fitness_score_cell'], match_first_elem.iloc[1]['fitness_score_organism']])

                    # mutation_type.csv
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(5), match.group(2),
                         match_first_elem.iloc[1]['replicate'],
                         match_first_elem.iloc[1]['cell'], 'beneficial', beneficial_leading, beneficial_overall,
                         ((beneficial_leading / ben_del_neu_leading_all) if ben_del_neu_leading_all > 0 else 0),
                         ((beneficial_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         ((beneficial_leading / ben_del_neu_no_leading_all) if ben_del_neu_no_leading_all > 0 else 0),
                         ((beneficial_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(5), match.group(2),
                         match_first_elem.iloc[1]['replicate'],
                         match_first_elem.iloc[1]['cell'], 'deleterious', deleterious_leading, deleterious_overall,
                         ((deleterious_leading / ben_del_neu_leading_all) if ben_del_neu_leading_all > 0 else 0),
                         ((deleterious_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         ((deleterious_leading / ben_del_neu_no_leading_all) if ben_del_neu_no_leading_all > 0 else 0),
                         ((deleterious_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(5), match.group(2),
                         match_first_elem.iloc[1]['replicate'],
                         match_first_elem.iloc[1]['cell'], 'neutral', neutral_leading, neutral_overall,
                         ((neutral_leading / ben_del_neu_leading_all) if ben_del_neu_leading_all > 0 else 0),
                         ((neutral_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         ((neutral_leading / ben_del_neu_no_leading_all) if ben_del_neu_no_leading_all > 0 else 0),
                         ((neutral_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])
                    csv_mutation_type.writerow(
                        [match.group(1), pop_mut, match.group(3), match.group(5), match.group(2),
                         match_first_elem.iloc[1]['replicate'],
                         match_first_elem.iloc[1]['cell'], 'no_mutation', no_mutation_leading, no_mutation_overall,
                         0, ((beneficial_overall / ben_del_neu_overall_all) if ben_del_neu_overall_all > 0 else 0),
                         0, ((no_mutation_overall / ben_del_neu_no_overall_all) if ben_del_neu_no_overall_all > 0 else 0)])


            # update indices after intra-run comparisons
            start_index = end_index
            end_index += inter_run_reps * 2
            print('Intra-run finished.')

            # continue with inter-run comparison
            current_df = df[start_index:end_index]
            current_rep = current_df.loc[start_index]['replicate']
            categories = [i for i in (list(range(current_rep, current_rep + inter_run_reps)))]

            pairs = []
            while len(categories) > 1:
                rand1 = pop_random(categories)
                rand2 = pop_random(categories)
                pair = rand1, rand2
                pairs.append(pair)

            for elem in pairs:
                current_a_temp = current_df.loc[df['replicate'] == elem[0]]  # elem[0] is first replicate of the pair
                current_a = current_a_temp.loc[current_df['cell'] == 'A']
                current_b_temp = current_df.loc[df['replicate'] == elem[1]]  # elem[1] is second replicate of the pair
                current_b = current_b_temp.loc[current_df['cell'] == 'B']

                match_a = re.search(match_pattern_scenario, current_a.iloc[0]['experiment'])
                match_b = re.search(match_pattern_scenario, current_b.iloc[0]['experiment'])
                pop_mut = match_a.group(2) + ', ' + match_a.group(4)
                for i in range(1, 5):
                    if match_a.group(i) != match_b.group(i):
                        print('Error in matches (intra-run).')
                variance_leading = compute_amm(current_a.iloc[0]['leading_one_mutations'],
                                               current_b.iloc[0]['leading_one_mutations'])
                variance_overall = compute_amm(current_a.iloc[0]['overall_mutations'],
                                               current_b.iloc[0]['overall_mutations'])

                variance_leading_switched = compute_amm(current_b.iloc[0]['leading_one_mutations'],
                                                        current_a.iloc[0]['leading_one_mutations'])
                variance_overall_switched = compute_amm(current_b.iloc[0]['overall_mutations'],
                                                        current_a.iloc[0]['overall_mutations'])

                csv_amm.writerow(
                    [match_a.group(1), pop_mut, match_a.group(3), match_a.group(4), match_a.group(5), match_a.group(2),
                     'inter-run', elem[0], elem[1], variance_leading, variance_overall])
                csv_amm_switched_pairs.writerow(
                    [match_a.group(1), pop_mut, match_a.group(3), match_a.group(4), match_a.group(5), match_a.group(2),
                     'inter-run', elem[1], elem[0], variance_leading_switched, variance_overall_switched])

            # update indices after inter-run comparisons
            start_index = end_index
            end_index += inter_treatment_reps * 2
            print('Inter-run finished.')

            # continue with inter-treatment comparison
            current_df = df[start_index:end_index]
            current_rep = current_df.loc[start_index]['replicate']

            categories_curr_scenario = [i for i in
                                        (list(range(current_rep, int(current_rep + inter_treatment_reps / 2))))]
            categories_drift = [i for i in (
                list(range(int(current_rep + inter_treatment_reps / 2), current_rep + inter_treatment_reps)))]

            pairs = []

            while len(categories_curr_scenario) > 0 and len(categories_drift) > 0:
                rand1 = pop_random(categories_curr_scenario)
                rand2 = pop_random(categories_drift)
                pair = [rand1, rand2]
                random.shuffle(pair)
                pairs.append(tuple(pair))

            for elem in pairs:
                current_a_temp = current_df.loc[df['replicate'] == elem[0]]  # elem[0] is first replicate of the pair
                current_a = current_a_temp.loc[current_df['cell'] == 'A']
                current_b_temp = current_df.loc[df['replicate'] == elem[1]]  # elem[1] is second replicate of the pair
                current_b = current_b_temp.loc[current_df['cell'] == 'B']

                if len(current_a.iloc[0]['experiment']) > len(current_b.iloc[0]['experiment']):
                    match_a = re.search(match_pattern_drift, current_a.iloc[0]['experiment'])
                    match_b = re.search(match_pattern_scenario, current_b.iloc[0]['experiment'])
                    match = match_b
                else:
                    match_a = re.search(match_pattern_scenario, current_a.iloc[0]['experiment'])
                    match_b = re.search(match_pattern_drift, current_b.iloc[0]['experiment'])
                    match = match_a
                pop_mut = match.group(2) + ', ' + match.group(4)

                for i in (1, 2, 4):  # group 3 = scenario name, not compared since it must differ (current vs. drift)
                    if match_a.group(i) != match_b.group(i):
                        print(i, ' Error in matches (intra-treatment).')
                variance_leading = compute_amm(current_a.iloc[0]['leading_one_mutations'],
                                               current_b.iloc[0]['leading_one_mutations'])
                variance_overall = compute_amm(current_a.iloc[0]['overall_mutations'],
                                               current_b.iloc[0]['overall_mutations'])

                variance_leading_switched = compute_amm(current_b.iloc[0]['leading_one_mutations'],
                                                        current_a.iloc[0]['leading_one_mutations'])
                variance_overall_switched = compute_amm(current_b.iloc[0]['overall_mutations'],
                                                        current_a.iloc[0]['overall_mutations'])

                csv_amm.writerow(
                    [match.group(1), pop_mut, match.group(3), match.group(4), match.group(5), match.group(2),
                     'inter-treatment', elem[0], elem[1], variance_leading, variance_overall])
                csv_amm_switched_pairs.writerow(
                    [match.group(1), pop_mut, match.group(3), match.group(4), match.group(5), match.group(2),
                     'inter-treatment', elem[1], elem[0], variance_leading_switched, variance_overall_switched])

            # update indices after inter-treatment comparison
            start_index = end_index
            end_index += intra_run_reps * 2
            print('Inter-treatment finished.')


if __name__ == "__main__":
    generate_csv_files('final_processed_data_equal_mutation_rates.csv')
    #generate_csv_files('final_processed_data_different_mutation_rates.csv')
