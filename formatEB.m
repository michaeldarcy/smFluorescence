function [ EB_format ] = formatEB(fn,savename)
%This script takes in a .mat traces file and formats it for .dat import to ebFRET

file = load(fn)
disp('file name is')
disp(file)



traces= file.traces;
len = length(traces)

acptr= {traces(:).acptr};
donr= {traces(:).donr};


for i = 1:len;   
trace_length = length(traces(i).acptr);
%twos = 2.* ones(length(x),1)
%A(1:trace_length,1:1) = i;
s(i).frame = i*ones(trace_length,1);

%try the normalization here
s(i).donr = (traces(i).donr)/(min(traces(i).donr))-0.95;
s(i).acptr= traces(i).acptr/(min(traces(i).acptr))-0.95;

%s(i).acptr = i;
end

%don't know a good way to do this
frame_all= {s(:).frame};
frame_all= transpose(frame_all);
frame_all = cell2mat(frame_all);

acptr_all= {s(:).acptr};
acptr_all= transpose(acptr_all);
acptr_all = cell2mat(acptr_all);

donr_all= {s(:).donr};
donr_all= transpose(donr_all);
donr_all = cell2mat(donr_all);


EB_format = [frame_all,donr_all,acptr_all];
assignin('base','EB_format',EB_format);
assignin('base','s',s);

%filename = [fn,'forEB.txt']
%save(filename, EB_format)
save(savename,'EB_format','-ascii');

%assignin('base','donr',donr);
%{
B = struct2table(s);
assignin('base','B',B);


C =table2array(B);
assignin('base','C',C);
%}
%}
%}
end