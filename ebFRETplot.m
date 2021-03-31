function ebFRETplot (filename)
files = dir(filename)

for file = files'
    howmanyeventsgraphed = .95;
    load(file.name)
    figure()
    plot (X_low, F_low, 'ks', 'MarkerSize',10, 'LineWidth', 1)
    hold on
    
     %%% PLOT SINGLE EXPONENTIAL FIT 
    [userPDF, dataVar, fitVar, lb,ub, ~]=PDFList('Single Exp', 'all', 0);
    annealTemp=5;
    guess = '1'; 
    [statlow, logLikli]= MEMLETCL(tlow', userPDF, dataVar, fitVar, lb,ub, guess,annealTemp);
    statlow
    plotVarx=linspace(0,max(tlow),10000)'; %create variables for plotting along x
    
    fittedsl= exppdfcalcnotmin(plotVarx, statlow) ;
    fittedCDF1=cumtrapz(fittedsl(~isnan(fittedsl))); %take out any NaNs when doing cumulative (maybe at x=0?) 
    fittedCDF2=fittedCDF1/max(fittedCDF1); %normalize CDF
    plot(plotVarx(~isnan(fittedsl)),fittedCDF2, 'b', 'LineWidth', 4)
    hold on
    
    xlabel('Time (s) for 5Hz') 
    ylabel('Cumulative Probability')
    [~, closestIndex] = min(abs(howmanyeventsgraphed - F_low.'));
    set(gca, 'YScale', 'log')
    set(gcf,'color','w');
    title(file.name)
    hold on
    
    
    
    
    
  
    plot (X_high, F_high, 'ko', 'MarkerSize',10, 'LineWidth', 1)
    hold on
    [userPDF, dataVar, fitVar, lb,ub, ~]=PDFList('Single Exp', 'all', 0);
    annealTemp=5;
    guess = '1'; 
    [stathigh, logLikli]= MEMLETCL(thigh', userPDF, dataVar, fitVar, lb,ub, guess,annealTemp);
    stathigh
    plotVarx=linspace(0,max(thigh),10000)'; %create variables for plotting along x
    
    fittedsh= exppdfcalcnotmin(plotVarx, stathigh) ;
    fittedCDF1=cumtrapz(fittedsh(~isnan(fittedsh))); %take out any NaNs when doing cumulative (maybe at x=0?) 
    fittedCDF2=fittedCDF1/max(fittedCDF1); %normalize CDF
    plot(plotVarx(~isnan(fittedsh)),fittedCDF2, 'r', 'LineWidth', 4)
    hold on
   
    xlabel('Time (s) for 5Hz') 
    ylabel('Cumulative Probability')
    [~, closestIndex] = min(abs(howmanyeventsgraphed - F_high.'));
    set(gca, 'YScale', 'log')
    set(gcf,'color','w');
    %axis([-.05*X_high(closestIndex) X_high(closestIndex) F_high(2)/1.3 1.4]) 
    axis([-20 500 .008 1.4])
    %%legend ('Closing data', 'closing fit' , 'opening data', 'opening')
    hold on
   
    
    %axis([-.05*X_low(closestIndex) X_low(closestIndex) F_low(2)/1.3 1]) 
end