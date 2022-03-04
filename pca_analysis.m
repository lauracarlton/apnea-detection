
addpath('/Users/jtam/Desktop/school/BIEN470/GITHUB/reklab_public/utility_tools/')
addpath('/Users/jtam/Desktop/school/BIEN470/GITHUB/reklab_public/nlid_tools/')
addpath('/Users/jtam/Dropbox/ApnexDetection_Project/MATLAB tools/jsonlab-2.0/jsonlab-2.0/')
addpath('/Users/jtam/Desktop/school/BIEN470/GITHUB/apnea-detection/Untitled')
addpath('/Users/jtam/Dropbox/AUREA_retrieved_v2/METRICS/')
addpath('/Users/jtam/Dropbox/AUREA_retrieved_v2/Signal_Processing/')
addpath('/Users/jtam/Dropbox/AUREA_retrieved_v2/CardioRespiratory_Analysis/')
addpath('/Users/jtam/Dropbox/AUREA_retrieved_v2/biplotG/')

%%

%run section 1 of MachineLearning.m first

input=table2array(Table_Train(:,1:66));
labels=table2array(Table_Train(:,67));

[coeff,score,latent,~,explained]=pca(input);

categories=fieldnames(T);
categories=categories(1:66);

%define labels for data types for colour coding in biplotG
groups=zeros(length(labels),1);
for t=1:length(labels)
    if labels(t)=='N'
        groups(t)=1;
    elseif labels(t)=='V'
        groups(t)=2;
    elseif labels(t)=='O'
        groups(t)=3;
    end
end

%visualize data: biplotG, biplot provide plots of PCs against data points
%to assess clustering
%mapcaplot provides an interactive interface to plot individual PCs against
%each other

% biplotG(coeff, score, 'Groups', groups, 'Varlabels', categories)
% figure()
% biplot(coeff(:,1:3),'Scores',score(:,1:3),'Varlabels',categories);
% mapcaplot(input,labels);

%%


%convert T1 to doubles
a_test=table2array(Table_Test);
a_test=str2double(a_test);

pca_terms_test=zeros(66,66);
pca_values=zeros(length(a_test),66);

%compute PC values by multiplying coefficients and corresponding metric
%values, then summing all terms

for n=1:length(a_test)
    
    %computes values for each term for each PC 
    %selected top 9 PCs based on % variance accounted for (cut-off = 2%)
    
    for t=1:66
        pca_terms_test(:,t)=(a_test(n,1:66))'.*coeff(:,t);
    end
    
    %computes values for each PC by summing terms
    
    pca_values(n,:)=sum(pca_terms_test,1);

end

pca_values_balanced_test=array2table(pca_values);
pca_values_balanced_test(:,67)=Table_Test(:,67);

%%

principal_metrics=zeros(10,6);

for t=1:6
    [~,principal_metrics(:,t)]=maxk(coeff(:,t),10,'ComparisonMethod','abs');
end
