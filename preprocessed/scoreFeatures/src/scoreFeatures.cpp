#include<iostream>
#include<stdio.h>

using namespace std;

int main(int argc, char** argv){

	/*Ensure inputs are correct */
	if (argc != 3){
		cout << "Usage: scoreFeatures histograms.txt labels.txt" << endl;
		return -1;
	}

	/* Get input file names */
	cout<< "Histogram Input: " << argv[1] << endl;
	cout<< "Label Input: " << argv[2] << endl;
	char* histFN = argv[1];
	char* labelFN = argv[2];

	/* Open files */
	FILE* histograms = fopen(histFN, "r");
	FILE* labels = fopen(labelFN, "r");

	return 0;
}
