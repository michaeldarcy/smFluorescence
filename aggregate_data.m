
function aggregate_data (template_string)

%%set default value for template string if none provided
if isempty(template_string)
    template_string = 'norm*catcut.mat';
end

%% load all files that fit the template string
files = dir(template_string);
a = 1;


%%add each file's data and traces to the aggregator and save it
%%needs traces to be organized into variables data and traces
%%data is a 1XN cell array with each entry as a Tx2 trace where T is the
%%number of frames in the trace, the first column is the donor data and
%%second the acceptor.


%%traces is a 1xN struct with the following fields:
%%   donr - a Tx1 double array
%%   acptr - a Tx1 double array
%%   IndT - a binary flag set to 1, unused
%%   imName - a char array with the filename of the source image file
%%   position - a [x,y] array
%%   catagory - either [] or a string indicating the assigned category from
%%        TracesView2
%%   idealAcptr and ideal Donr -- 2 fields of empty arrays, unused

for file = files'
    load(file.name)
    if a == 1
        aggregatedata = data;
        aggregatetraces = traces;
    else
        dataold = aggregatedata;
        tracesold = aggregatetraces;
        aggregatedata = [dataold, data];
        aggregatetraces = [tracesold, traces];
    end
    save('aggregatecatcut.mat', 'aggregatedata', 'aggregatetraces')
    load('aggregatecatcut.mat', 'aggregatedata', 'aggregatetraces')
    a = a+1
end
data = aggregatedata;
traces = aggregatetraces;
save('aggregatecatcut.mat', 'data', 'traces')