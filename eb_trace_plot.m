function eb_trace_plot (filename)

files = dir(filename)

for file = files'
    if strcmp(file.name, 'plotsave*.mat')
        continue
    end
    figure
    
    eb_raw = dlmread(strcat(file.name, 'save.dat'));

    q = 1;
    m = 1;
    eb_data = zeros (1000, 1);
    eb_traces = {};
    for i = 1:length(eb_raw)
        if eb_raw(i, 1)  ==   q
            eb_data(m) = eb_raw(i, 2);
            m = m+1;
        else
            eb_traces(q) = {eb_data};
            eb_data = zeros(1000,1);
            eb_data(1) = eb_raw(i, 2);
            q = q +1;
            m = 2;
        end

    end
    eb_traces(q) = {eb_data};

    pan = panel();
    set(gcf,'color','w');
    pan.pack(6, 2);
    load (file.name)
    b = 1;
    for i= 1:length(eb_traces)
        pan(mod (b,6)+1, ceil(b/6)).select();
        plot(cell2mat(eb_traces(i)),'r','LineWidth',2);
        hold on;
        trace = cell2mat(data(i));
        fret = zeros(length(trace),1);
        for i = 1:length(trace)
            fret(i) = trace(i,2) / (trace(i,1) + trace(i,2));
        end
        plot(fret,'LineWidth', .15,'color','black');
        axis([0,1600, 0, 1])
        hold off;
        if mod(b,12) == 0
            figure
            pan= panel();
            set(gcf,'color','w');
            pan.pack(6,2);
            b=0;
        end
        b = b +1;
    end
end