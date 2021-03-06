%Select Features
%This script will select the best features based off of the feature score
%given by scoreFeatures().

clear,clc, close all
%---------- SET EXECUTION PARAMETERS ---------------------
%Get file names
K = 30; %number of desired features
label_fn = 'labels.txt';
features_fn = 'features.txt';
features_info_fn = 'features_info.txt';
runInparallel = 0;
plotEachHistogram = 0;
saveHistograms = 1;
%---------------------------------------------------------

%Add path to scoreFeatures
addpath('./scoreFeatures/');

%import labels vector (1 x N)
labels = load(label_fn);
labels = labels';
%import feature histograms (F x N)
histograms = load(features_fn);
histograms = histograms';
%import feature information
features_info_fd = fopen(features_info_fn);
info = textscan(features_info_fd, '%s', 'delimiter', '\n');
info = info{1};
fclose(features_info_fd);

%Ensure that there are the same number of Positive and Negative Examples
nPositive = find(labels == 1);
nNegative = find(labels == -1);
equalNumber = min([length(nPositive) length(nNegative)]);
nPositive = nPositive(1:equalNumber);
nNegative = nNegative(1:equalNumber);
histograms = histograms(:, [nPositive, nNegative]);
labels = [ labels(nPositive) , labels(nNegative) ];

%Eliminate obviously bad features (using tf-idf)
[histograms, labels, info ] = reduceDictionary(histograms, labels, info);

%Score Features
scores = scoreFeatures(histograms, labels, info, plotEachHistogram, runInparallel);

%Sort Features based on scores (Hamming Distance & Tanimoto Distance)
[sorted hammingInds] = sort(abs(scores(:,1)), 'descend');
[sorted tanimotoInds]= sort(abs(scores(:,2)), 'descend');
%get top K scored features for each distance
hammingInds = hammingInds(1:K);
tanimotoInds = tanimotoInds(1:K);
%Get top K scored distances and infos
hammingDistance = scores(hammingInds,1);
tanimotoDistance = scores(tanimotoInds, 2);
hammingInfo = info(hammingInds);
tanimotoInfo= info(tanimotoInds);
%find unique distanceInds and once again reduce
combinedInds = [hammingInds ; tanimotoInds];
uniqueInds = unique(combinedInds);

%Get tope scored histograms and labels
topHistograms = histograms(uniqueInds, :);

%Remove duplicates for each unique value
for k = 1:length(uniqueInds)
   if sum(combinedInds == uniqueInds(k)) > 1
      duplicate_tanimoto_Inds = find( tanimotoInds == uniqueInds(k));
      duplicate_hamming_Inds = find(hammingInds == uniqueInds(k));
      if duplicate_tanimoto_Inds <= duplicate_hamming_Inds
            tanimotoDistance(duplicate_tanimoto_Inds) = nan;
      else
            hammingDistance(duplicate_hamming_Inds) = nan;
      end
   end
end
%Prune off NaNs
hammingInfo(isnan(hammingDistance)) = [];
tanimotoInfo(isnan(tanimotoDistance)) = [];
hammingDistance(isnan(hammingDistance)) = [];
tanimotoDistance(isnan(tanimotoDistance)) = [];


%------ SET WEIGHTS -------
%Set weighting scheme parameters
hammingSlope = 5;
hammingScale = 3;%5
tanimotoSlope = 10;
tanimotoScale = 10000;%1000
%Set weights to be exponentially derived from distances
hamming_weight = sign(hammingDistance).*...
    exp(hammingSlope.*abs(hammingDistance))./hammingScale;
tanimoto_weight = sign(tanimotoDistance).*...
    exp(tanimotoSlope*abs(tanimotoDistance))./tanimotoScale;


%Output selected features, type of metric weight (Hamming vs. wordCount), weight
FeatureInfos = [ hammingInfo ; tanimotoInfo ];

hammingMetric = {'H'}; hammingMetric = repmat(hammingMetric, ...
    [length(hamming_weight), 1]);
wordCountMetric = {'WC'}; wordCountMetric = repmat(wordCountMetric, ...
    [length(tanimoto_weight), 1]);
Metrics = [ hammingMetric ; wordCountMetric ];

Weights = [ hamming_weight ; tanimoto_weight ];

fd = fopen('selectedFeatures.txt', 'wt');
for k = 1:length(Weights)
    if saveHistograms
        %Partition histograms by positive or negative label
        positive = topHistograms(k, find(labels == 1));
        negative = topHistograms(k, find(labels ==-1));

        %sort partitioned training data
        positive = sort(positive, 'descend');
        negative = sort(negative, 'descend');
    
        maxY = max([positive, negative]);
        posColor = [0, 154, 159]./255;
        negColor = [192, 83, 69 ]./255;

        figure(1)
        clf;
        pp = [positive, nan(1, length(negative)+1)];
        nn = [nan(1, length(positive) + 1), negative];
        bar(pp, 'FaceColor', posColor, 'EdgeColor', posColor); hold on;
        bar(nn, 'FaceColor', negColor, 'EdgeColor', negColor);
        plot((length(positive) + 1) .* ones(2,1), [0 maxY+10], 'Color',...
            [138,137, 137]./255, 'LineWidth', 2, 'LineStyle', '--');
        ylim([0 maxY+1]);
        xlim([0 length(positive)+length(negative)+1]);
        set(gca, 'XTickLabel', {});
        xlabel('Positive vs. Negative Documents', 'FontSize', 18);
        ylabel('Features per Document', 'FontSize', 18);
        title(['Feature: ' FeatureInfos{k}], 'fontsize',18);
        text(length(positive)+100, maxY-1, [Metrics{k} ': ' num2str(Weights(k))],...
            'Fontsize',18);
        pause; 
    end
    
    
    fprintf(fd, '%s\t%s\t%.3f\n', FeatureInfos{k}, Metrics{k}, Weights(k));
end
fclose(fd);





