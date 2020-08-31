//  MABE is a product of The Hintze Lab @ MSU
//     for general research information:
//         hintzelab.msu.edu
//     for MABE documentation:
//         github.com/Hintzelab/MABE/wiki
//
//  Copyright (c) 2015 Michigan State University. All rights reserved.
//     to view the full license, visit:
//         github.com/Hintzelab/MABE/wiki/License

#pragma once

#include "../AbstractWorld.h"

#include <cstdlib>
#include <thread>
#include <vector>
#include <bitset>
#include <tuple>


class MigrationWorld : public AbstractWorld {

public:
	static const int tagSize = 100;

	static std::shared_ptr<ParameterLink<double>> aMutationRatePL;
	static std::shared_ptr<ParameterLink<double>> bMutationRatePL;
	static std::shared_ptr<ParameterLink<double>> migrationRatePL;

	std::set<std::shared_ptr<Organism>> killList;

	class Agent {
	public:
		std::shared_ptr<Organism> org;
		std::bitset<tagSize> genome;
		double score = 0.0;
		double dualScore = 0.0;
		Agent() {}
		Agent(std::shared_ptr<Organism> org_, const std::bitset<tagSize>& genome_) : org(org_), genome(genome_) {}
	};

	class DualAgent {
	public:
		std::shared_ptr<Agent> A;
		std::shared_ptr<Agent> B;
		double score = 0.0;
		bool isFromGroup;
		DualAgent() {}
		DualAgent(std::shared_ptr<Agent> A_, std::shared_ptr<Agent> B_) : A(A_), B(B_) {}
	};

	MigrationWorld(std::shared_ptr<ParametersTable> PT_ = nullptr);
	virtual ~MigrationWorld() = default;

	void evaluate(std::map<std::string, std::shared_ptr<Group>>& groups, int analyze, int visualize, int debug);

	void initializeGeneration(std::vector<std::shared_ptr<Agent>>& popA, std::vector<std::shared_ptr<Agent>>& popB, std::vector<DualAgent>& popDual, std::map<std::string, std::shared_ptr<Group>>& groups, int popSize);
	std::tuple<std::shared_ptr<Agent>, std::shared_ptr<Agent>> doTournamentSelectionGroup(int popSize, const std::vector<double>& scoreDual, std::vector<DualAgent>& popDual, std::map<std::string, std::shared_ptr<Group>>& groups, int tournamentSize);
	int doTournamentSelectionIndividual(int popSize, const std::vector<double>& scoreIndividual, int tournamentSize);

	void mutateSelection(std::shared_ptr<Agent>& newA, std::shared_ptr<Agent>& newB);
	void killOldAndMakeNewGeneration(std::vector<std::shared_ptr<Agent>>& popA, std::vector<std::shared_ptr<Agent>>& popB, std::vector<DualAgent>& popDual, std::map<std::string, std::shared_ptr<Group>>& groups, int popSize);

	std::tuple<double, double, double> evalDual(DualAgent& dualAgent);

	void addToDataMap(DualAgent& dualAgent);

	double evalGroup(DualAgent& dualAgent);
	double evalAgentA(std::bitset<tagSize>& testGenome);
	double evalAgentB(std::bitset<tagSize>& testGenome);

	virtual std::unordered_map<std::string, std::unordered_set<std::string>> requiredGroups() override;
};

