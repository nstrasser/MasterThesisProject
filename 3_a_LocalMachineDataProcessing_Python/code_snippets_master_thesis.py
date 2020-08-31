import statistics

def compute_amm(genome_a, genome_b):
    chunk_size = 100
    differentials = []
    if len(genome_a) == len(genome_b):
        for i in range(0, len(genome_a), chunk_size):
            beneficial_mut_a = genome_a[i:i+chunk_size].count('+')
            beneficial_mut_b = genome_b[i:i+chunk_size].count('+')
            differentials.append(beneficial_mut_a - beneficial_mut_b)
    return statistics.variance(differentials)



# print(compute_amm('oo++o+o-', 'o-+ooo++'))  # with chunk_size = 2  !!!