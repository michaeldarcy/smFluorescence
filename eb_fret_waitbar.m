function runs = eb_fret_waitbar(x, K_values, restarts, varargin)
    % eb_fret(x, K_values, restarts, varargin)
    %
    % Runs EB inference on a set of FRET time series.
    %
    % Inputs
    % ------
    %
    % x : (1xN) cell
    %   Time series to perform inference on
    %
    % K_values : (1xR)
    %   Number of states to use for each run
    %
    % restarts : int
    %   Number of EB restarts to perform
    %
    % u0 : (1xR) struct (optional)
    %   Initial guess for hyperparameters to use for first restart
    %   of each run
    %
    % w0 : (N x R) struct (optional)
    %   Initial guess for posterior parameters to use for 
    %   first restart of each run
    %
    % Variable Inputs
    % ---------------
    %
    % 'u0_strength' : float (default = 0.1)
    %   Strength of hyperparameters used in each EB restart.
    %   Specified as a fraction of the mean trace length. 
    %
    %   Note: this value is currently only applied to the emission
    %   model prior, where the transition rate prior is uninformative.
    %
    % 'num_cpu' : int (default = 1)
    %   Number of cpu's to use
    %
    % 'eb' : struct
    %   Any options to pass to eb algorithm
    %
    % 'vbem' : struct
    %   Any options to pass to vbem algorithm
    %
    %
    % Outputs
    % -------
    % 
    % runs : (1xR) struct
    %   Output of eb run for each K value (see eb_hmm.m)
    %
    %   .u struct
    %       Hyperparameters for ensemble distribution
    %   .L (1xI)
    %       Summed evidence for each hierarchical iteration
    %   .vb (1xN) struct    
    %       VBEM output for each trace
    %   .vit (1xN) struct
    %       Viterbi path for each trace
    %   .K int
    %       Number of states
    %   .u0 struct
    %       Initial guess for hyperparameters

    % parse input
    w = waitbar(0 ,"Parsing inputs...");
    ip = inputParser();
    ip.StructExpand = true;
    ip.addRequired('x', @iscell);
    ip.addRequired('K_values', @isnumeric);
    ip.addOptional('restarts', 1, @isscalar);
    ip.addOptional('u0', struct(), @(u) isstruct(u) & isfield(u, 'mu'));
    ip.addOptional('w0', struct(), @(w) isstruct(w) & isfield(w, 'mu'));
    ip.addParamValue('u0_strength', 0.1, @isscalar);
    ip.addParamValue('num_cpu', 1, @isscalar);
    ip.addParamValue('eb', struct(), @isstruct);
    ip.addParamValue('vbem', struct(), @isstruct);
    ip.parse(x, K_values, restarts, varargin{:});
    opts = ip.Results;
    w = waitbar(0.05,w ,"Starting multithreaded parallel pool...");
    % open matlabpool if using mutliple CPU's
    if opts.num_cpu > 1
        parpool(opts.num_cpu);
    end
    waitbar(0.08,w ,"Setting defaults for priors...");
    % set defaults for any missing options
    opts_eb = eb_defaults();
    fnames = fieldnames(opts_eb);
    for f = 1:length(fnames)
        if ~isfield(opts.eb, fnames{f})
            opts.eb.(fnames{f}) = opts_eb.(fnames{f});
        end
    end
    opts_vbem = vbem_defaults();
    fnames = fieldnames(opts_vbem);
    for f = 1:length(fnames)
        if ~isfield(opts.vbem, fnames{f})
            opts.vbem.(fnames{f}) = opts_vbem.(fnames{f});
        end
    end
    waitbar(0.10, w ,"Initial inference pass");
    try
        % calculate counts to assign to prior
        u0_counts = opts.u0_strength * mean(cellfun(@length, x));

        % generate set of initial guesses for hyperparameters
        for k = 1:length(opts.K_values)
            K = opts.K_values(k);
            if K > 1
                % set range of minimum separations for FRET levels of states
                % low minimum separation means high randomness
                % high minimum seperation means evenly spread states 
                % on interval [0, 1]
                sep_range = (0.98 * linspace(0, 1, opts.restarts) + 0.02) ...
                            / (opts.K_values(k) - 1);
            end
            for r = 1:opts.restarts
                if r == 1 & isfield(opts.u0, 'mu')
                    % use supplied hyperparameters for first restart
                    u0(k, r) = opts.u0(k);
                else
                    if K >1
                        u0(k, r) = init_u(K, 'mu_sep', sep_range(r), ...
                                         'mu_counts', u0_counts);
                    else
                        u0(k, r) = init_u(K, 'mu_counts', u0_counts);
                    end
                end
            end
        end

        % run eb for every set of hyperparameters
        runs = cell(length(opts.K_values), 1);
        for k = 1:length(opts.K_values)
            rn = cell(opts.restarts, 1);
            for r = 1:opts.restarts
                waitbar(0.10 + 0.9*r/opts.restarts, w ,strcat("Cycle number ", int2str(r), " of ", int2str(opts.restarts)));
                rn{r} = struct();
                if r == 1 & isfield(opts.w0, 'mu')
                    [rn{r}.u, rn{r}.L, rn{r}.vb, rn{r}.vit] = ...
                        eb_hmm_waitbar(x, u0(k,r), 'w0', opts.w0(:,k), opts.eb, 'vbem', opts.vbem, 'display', 'trace');
                else
                    [rn{r}.u, rn{r}.L, rn{r}.vb, rn{r}.vit] = ...
                        eb_hmm_waitbar(x, u0(k,r), opts.eb, 'vbem', opts.vbem);
                end
                rn{r}.K = opts.K_values(k);
                rn{r}.u0 = u0(k, r);
            end
            runs{k} = rn;
        end
        runs = cat(1, runs{:});
        runs = reshape([runs{:}], [length(opts.K_values), opts.restarts]);

        % keep best run
        L = arrayfun(@(r) r.L(end), runs);
        kdxs = bsxfun(@eq, L, max(L, [], 2)) * (1:opts.restarts)';
        rdxs = (kdxs-1) * length(opts.K_values) + (1:length(opts.K_values))';
        runs = runs(rdxs);
    catch ME
        % ok something went wrong here, so dump workspace to disk for inspection
        day_time =  datestr(now, 'yymmdd-HH.MM');
        save_name = sprintf('crashdump-eb_fret-%s.mat', day_time);
        save(save_name);

        % close matlabpool if necessary
        if opts.num_cpu > 1
            delete(gcp('nocreate'));
        end

        rethrow(ME);
    end
