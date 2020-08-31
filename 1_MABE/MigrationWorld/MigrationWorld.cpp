//  MABE is a product of The Hintze Lab @ MSU
//     for general research information:
//         hintzelab.msu.edu
//     for MABE documentation:
//         github.com/Hintzelab/MABE/wiki
//
//  Copyright (c) 2015 Michigan State University. All rights reserved.
//     to view the full license, visit:
//         github.com/Hintzelab/MABE/wiki/License

#include "MigrationWorld.h"

std::shared_ptr<ParameterLink<double>> MigrationWorld::aMutationRatePL = Parameters::register_parameter("WORLD_MIGRATION-aMutationRate", 0.01,
	"Mutation rate of agents from type A.");
std::shared_ptr<ParameterLink<double>> MigrationWorld::bMutationRatePL = Parameters::register_parameter("WORLD_MIGRATION-bMutationRate", 0.01,
	"Mutation rate of agents from type B.");
std::shared_ptr<ParameterLink<double>> MigrationWorld::migrationRatePL = Parameters::register_parameter("WORLD_MIGRATION-migrationRate", 0.5,
	"Probability of migration/migration rate (between 0.0 and 1.0).");


MigrationWorld::MigrationWorld(std::shared_ptr<ParametersTable> PT_) : AbstractWorld(PT_)
{
	// columns to be added to ave file
	popFileColumns.clear();
	popFileColumns.push_back("isFromGroup");
	popFileColumns.push_back("scoreA");
	popFileColumns.push_back("scoreB");
	popFileColumns.push_back("score");
}

void MigrationWorld::evaluate(std::map<std::string, std::shared_ptr<Group>>& groups, int analyze, int visualize, int debug)
{
	int popSize = groups["A::"]->population.size();
	std::vector<std::shared_ptr<Agent>> popA(popSize);
	std::vector<std::shared_ptr<Agent>> popB(popSize);
	std::vector<DualAgent> popDual(popSize);
	std::vector<double> groupScores(popSize, 0.0);
	std::vector<double> aScores(popSize, 0.0);
	std::vector<double> bScores(popSize, 0.0);

	int migratedAmount = popSize * migrationRatePL->get(PT);
	int notMigratedAmount = popSize - migratedAmount;

	initializeGeneration(popA, popB, popDual, groups, popSize);

	do
	{
		for (int i = 0; i < popSize; i++)
		{
			auto [ aScore, bScore, groupScore ] = evalDual(popDual[i]);
			aScores[i] = aScore;
			bScores[i] = bScore;
			groupScores[i] = groupScore;

			killList.insert(popDual[i].A->org);
			killList.insert(popDual[i].B->org);
		}

		// high-level selection (groups that move on; no migration is happening)
		for (int i = 0; i < notMigratedAmount; i++) {
			auto newA = std::make_shared<Agent>();
			auto newB = std::make_shared<Agent>();

			tie(newA, newB) = doTournamentSelectionGroup(popSize, groupScores, popDual, groups, 7);
			mutateSelection(newA, newB);

			auto newDual = DualAgent(newA, newB);
			newDual.isFromGroup = true;

			popDual.push_back(newDual);
			popA.push_back(newA);
			popB.push_back(newB);

			popDual.back().A->org->dataMap.set("score", 0.0);
			popDual.back().B->org->dataMap.set("score", 0.0);
		}

		// low-level selection (individuals that are paired as groups and then move on; migration is happening)
		for (int i = 0; i < migratedAmount; i++) {
			// select for individuals (their parentIds for now) instead of pairs!
			int newParentIdA = doTournamentSelectionIndividual(popSize, aScores, 7);
			auto newOrgA = popDual[newParentIdA].A->org->makeMutatedOffspringFrom(popDual[newParentIdA].A->org);
			groups["A::"]->population.push_back(newOrgA);
			auto newA = std::make_shared<Agent>(newOrgA, popDual[newParentIdA].A->genome);

			int newParentIdB = doTournamentSelectionIndividual(popSize, bScores, 7);
			auto newOrgB = popDual[newParentIdB].B->org->makeMutatedOffspringFrom(popDual[newParentIdB].B->org);
			groups["B::"]->population.push_back(newOrgB);
			auto newB = std::make_shared<Agent>(newOrgB, popDual[newParentIdB].B->genome);

			mutateSelection(newA, newB);

			// pair them
			auto newDual = DualAgent(newA, newB);
			newDual.isFromGroup = false;

			popDual.push_back(newDual);
			popA.push_back(newA);
			popB.push_back(newB);

			popDual.back().A->org->dataMap.set("score", 0.0);
			popDual.back().B->org->dataMap.set("score", 0.0);
		}

		groups["A::"]->archive();
		groups["B::"]->archive();

		killOldAndMakeNewGeneration(popA, popB, popDual, groups, popSize);

		std::cout << "finished update: " << Global::update << std::endl;
		Global::update++;
	} while (!groups["A::"]->archivist->finished_ && !groups["B::"]->archivist->finished_);

	std::cout << "finished run!" << std::endl;
}

void MigrationWorld::initializeGeneration(std::vector<std::shared_ptr<Agent>>& popA, std::vector<std::shared_ptr<Agent>>& popB, std::vector<DualAgent>& popDual, std::map<std::string, std::shared_ptr<Group>>& groups, int popSize)
{
	for (int i = 0; i < popSize; i++)
	{
		popA[i] = std::make_shared<Agent>(groups["A::"]->population[i], std::bitset<tagSize>());
		popB[i] = std::make_shared<Agent>(groups["B::"]->population[i], std::bitset<tagSize>());
		popDual[i] = DualAgent(popA[i], popB[i]);
		for (int j = 0; j < tagSize; j++)
		{
			popA[i]->genome[j] = 0; // this means that As start at maximum fitness - are they "willing" to drop from that to help the group?
			popB[i]->genome[j] = 0;
		}
	}
}

std::tuple<std::shared_ptr<MigrationWorld::Agent>, std::shared_ptr<MigrationWorld::Agent>> MigrationWorld::doTournamentSelectionGroup(int popSize, const std::vector<double>& scoreDual, std::vector<DualAgent>& popDual, std::map<std::string, std::shared_ptr<Group>>& groups, int tournamentSize)
{
	int parentId = Random::getIndex(popSize);
	int challenger;
	for (int j = 0; j < tournamentSize; j++)
	{
		challenger = Random::getIndex(popSize);
		if (scoreDual[challenger] > scoreDual[parentId])
		{
			parentId = challenger;
		}
	}

	auto newOrgA = popDual[parentId].A->org->makeMutatedOffspringFrom(popDual[parentId].A->org);
	groups["A::"]->population.push_back(newOrgA);
	auto newOrgB = popDual[parentId].B->org->makeMutatedOffspringFrom(popDual[parentId].B->org);
	groups["B::"]->population.push_back(newOrgB);
	auto newA = std::make_shared<Agent>(newOrgA, popDual[parentId].A->genome);
	auto newB = std::make_shared<Agent>(newOrgB, popDual[parentId].B->genome);

	return std::make_tuple(newA, newB);
}

int MigrationWorld::doTournamentSelectionIndividual(int popSize, const std::vector<double>& scoreIndividual, int tournamentSize)
{
	int parentId = Random::getIndex(popSize);
	int challenger;
	for (int j = 0; j < tournamentSize; j++)
	{
		challenger = Random::getIndex(popSize);
		if (scoreIndividual[challenger] > scoreIndividual[parentId])
		{
			parentId = challenger;
		}
	}

	return parentId;
}

void MigrationWorld::mutateSelection(std::shared_ptr<Agent>& newA, std::shared_ptr<Agent>& newB)
{
	int numMutations = Random::getBinomial(tagSize, aMutationRatePL->get(PT));
	for (int m = 0; m < numMutations; m++)
	{
		newA->genome.flip(Random::getIndex(tagSize));
	}

	numMutations = Random::getBinomial(tagSize, bMutationRatePL->get(PT));
	for (int m = 0; m < numMutations; m++)
	{
		newB->genome.flip(Random::getIndex(tagSize));
	}
}

void MigrationWorld::killOldAndMakeNewGeneration(std::vector<std::shared_ptr<Agent>>& popA, std::vector<std::shared_ptr<Agent>>& popB, std::vector<DualAgent>& popDual, std::map<std::string, std::shared_ptr<Group>>& groups, int popSize)
{
	popA = std::vector<std::shared_ptr<Agent>>(popA.begin() + popSize, popA.end());
	popB = std::vector<std::shared_ptr<Agent>>(popB.begin() + popSize, popB.end());
	popDual = std::vector<DualAgent>(popDual.begin() + popSize, popDual.end());

	std::vector<std::shared_ptr<Organism>> newOrgsA;
	std::vector<std::shared_ptr<Organism>> newOrgsB;
	// new and old generation in killList
	for (size_t i = 0; i < popSize * 2; i++)
	{
		if (killList.find(groups["A::"]->population[i]) == killList.end())
		{ // not in killList -> move to new population
			newOrgsA.push_back(groups["A::"]->population[i]);
		}
		if (killList.find(groups["B::"]->population[i]) == killList.end())
		{ // not in killList -> move to new population
			newOrgsB.push_back(groups["B::"]->population[i]);
		}
	}

	groups["A::"]->population = newOrgsA;
	groups["B::"]->population = newOrgsB;

	for (auto org : killList)
	{
		org->kill();
	}
	killList.clear();
}

std::tuple<double, double, double> MigrationWorld::evalDual(DualAgent& dualAgent) {
	dualAgent.A->score = evalAgentA(dualAgent.A->genome);
	dualAgent.B->score = evalAgentB(dualAgent.B->genome);
	dualAgent.score = evalGroup(dualAgent);

	dualAgent.A->dualScore = dualAgent.score;
	dualAgent.B->dualScore = dualAgent.score;

	addToDataMap(dualAgent);

	return { dualAgent.A->score, dualAgent.B->score, dualAgent.score };
}

void MigrationWorld::addToDataMap(DualAgent& dualAgent)
{
	dualAgent.A->org->dataMap.append("isFromGroup", dualAgent.isFromGroup);
	dualAgent.B->org->dataMap.append("isFromGroup", dualAgent.isFromGroup);

	dualAgent.B->org->dataMap.set("scoreA", dualAgent.A->score);
	dualAgent.B->org->dataMap.append("scoreB", dualAgent.B->score);

	dualAgent.A->org->dataMap.set("score", dualAgent.score);
	dualAgent.B->org->dataMap.set("score", dualAgent.score);

	// Not using those, but I have to write them to the dataMap anyways!
	dualAgent.A->org->dataMap.append("scoreA", dualAgent.A->score);
	dualAgent.A->org->dataMap.set("scoreB", dualAgent.B->score);
}

double MigrationWorld::evalGroup(DualAgent& dualAgent)
{
	double matchingBits = 0.0;
	for (int i = tagSize - 1; i >= 0; i--)
	{
		if (dualAgent.A->genome[i] == dualAgent.B->genome[i])
		{
			matchingBits++;
		}
	}
	return matchingBits;
}

double MigrationWorld::evalAgentA(std::bitset<tagSize>& testGenome)
{
	return (tagSize - testGenome.count())*1.0;
}

double MigrationWorld::evalAgentB(std::bitset<tagSize>& testGenome)
{
	return testGenome.count()*1.0;
}

std::unordered_map<std::string, std::unordered_set<std::string>> MigrationWorld::requiredGroups() {
	return { {"A::", {}}, {"B::", {}} };
}
