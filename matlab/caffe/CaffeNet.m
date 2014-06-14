classdef CaffeNet < handle
    properties (SetAccess = private)
        model_def_file = '../../examples/imagenet/imagenet_deploy.prototxt';
        model_file = '../../examples/imagenet/caffe_reference_imagenet_model';
        layers_info
        blobs_info
    end
    properties
        mode
        phase
        device_id
        input_blobs
        output_blobs
    end
    properties (Dependent)
        weights
    end
    properties (Access = private)
        init_key
        weights_changed = true;
        weights_store
    end
    methods (Access=private)
        function self = CaffeNet(model_def_file, model_file)
            if nargin == 0
                init(self, self.model_def_file, self.model_file);
            end
            if nargin > 0
                init_net(self, model_def_file);
            end
            if nargin > 1
                load_net(self, model_file);
            end
            self.mode = caffe('get_mode');
            self.phase = caffe('get_phase');
            self.device_id = caffe('get_device');
        end
    end
    methods (Static)
        function obj = instance(model_def_file, model_file)
            persistent self
            if isempty(self)
                switch nargin
                    case 2
                        self = CaffeNet(model_def_file, model_file);
                    case 1
                        self = CaffeNet(model_def_file);
                    case 0
                        self = CaffeNet();
                end
            else
                if nargin > 0 && ~isempty(model_def_file)
                    init_net(self,model_def_file);
                end
                if nargin > 1 && ~isempty(model_file)
                    load_net(self,model_file);
                end
            end
            obj = self;
        end
    end
    methods
        function weights = get.weights(self)
            if (is_initialized(self))
                if (self.weights_changed)
                    self.weights_store = caffe('get_weights');
                    self.weights_changed = false;
                end
                weights = self.weights_store;
            else
                weights = [];
            end
        end
        function set.weights(self,weights)
            if (is_initialized(self))
                caffe('set_weights', weights);
                self.weights_store = weights;
                self.weights_changed = false;
            end
        end
        function set.mode(self,mode)
            % mode = {'CPU' 'GPU'}
            switch mode
                case 'CPU'
                    caffe('set_mode_cpu');
                    self.mode = mode;
                case 'GPU'
                    caffe('set_mode_gpu');
                    self.mode = mode;
                otherwise
                    fprintf('Mode unknown choose between CPU and GPU\n');
                    error('Mode unknown');
            end
        end
        function set.phase(self, phase)
            % phase = {'TRAIN' 'TEST'}
            switch phase
                case 'TRAIN'
                    caffe('set_phase_train');
                    self.phase = phase;
                case {'test','TEST'}
                    caffe('set_phase_test');
                    self.phase = phase;
                otherwise
                    fprintf('Phase unknown choose between TRAIN and TEST')
                    error('Phase unknown');
            end
        end
        function set.device_id(self, device_id)
            caffe('set_device', device_id);
            self.device_id = device_id;
        end
        function set.input_blobs(self, input_blobs)
            if (is_initialized(self))
                caffe('set_input_blobs', input_blobs);
                self.input_blobs = input_blobs;
            end
        end
        function set.output_blobs(self, output_blobs)
            if (is_initialized(self))
                caffe('set_output_blobs', output_blobs);
                self.output_blobs = output_blobs;
            end
        end
    end
    methods
        function res = forward(~,input)
            if (is_initialized(self))
                if nargin < 2
                    res = caffe('forward');
                else
                    res = caffe('forward',input);
                end
            end
        end
        function res = backward(self,diff)
            if (is_initialized(self))
                assert(strcmp(self.phase,'TRAIN'),'Network should be in TRAIN phase');
                if nargin < 2
                    res = caffe('backward');
                else
                    res = caffe('backward',diff);
                end
            end
        end
        function res = forward_prefilled(~)
            if (is_initialized(self))
                res = caffe('forward_prefilled');
            end
        end
        function res = backward_prefilled(self)
            if (is_initialized(self))
                assert(strcmp(self.phase,'TRAIN'),'Network should be in TRAIN phase');
                res = caffe('backward_prefilled');
            end
        end
        function res = init(self, model_def_file, model_file)
            self.init_key = caffe('init',model_def_file, model_file);
            self.model_def_file = model_def_file;
            self.model_file = model_file;
            self.layers_info = caffe('get_layers_info');
            self.blobs_info = caffe('get_blobs_info');
            self.weights_changed = true;
            res = self.init_key;
        end
        function res = init_net(self, model_def_file)
            self.init_key = caffe('init_net',model_def_file);
            self.model_def_file = model_def_file;
            self.model_file = [];
            self.layers_info = caffe('get_layers_info');
            self.blobs_info = caffe('get_blobs_info');
            self.weights_changed = true;
            res = self.init_key;
        end
        function res = load_net(self, model_file)
            if (is_initialized(self))
                self.init_key = caffe('load_net',model_file);
                self.model_file = model_file;
                self.weights_changed = true;
                res = self.init_key;
            end
        end
        function res = save_net(~, model_file)
            if (is_initialized(self))
                res = caffe('save_net', model_file);
            end
        end
        function res = is_initialized(~)
            res = caffe('is_initialized');
        end
        function set_mode_cpu(self)
            self.mode = 'CPU';
        end
        function set_mode_gpu(self)
            self.mode = 'GPU';
        end
        function set_phase_train(self)
            self.phase = 'TRAIN';
        end
        function set_phase_test(self)
            self.phase = 'TEST';
        end
        function set_device(self, device_id)
            self.device_id = device_id;
        end
        function res = get_weights(self)
            if (is_initialized(self))
                res = self.weights;
            end
        end
        function set_weights(self, weights)
            self.weights = weights;
        end
        function res = get_layer_weights(self, layer_name)
            if (is_initialized(self))
                res = caffe('get_layer_weights', layer_name);
            end
        end
        function res = set_layer_weights(self, layer_name, weights)
            if (is_initialized(self))
                res = caffe('set_layer_weights', layer_name, weights);
                self.weights = caffe('get_weights');
            end
        end
        function res = get_layers_info(self)
            res = self.layers_info;
        end
        function res = get_blobs_info(self)
            res = self.blobs_info;
        end
        function res = get_blob_data(self, blob_name)
            if (is_initialized(self))
                res = caffe('get_blob_data', blob_name);
            end
        end
        function res = get_blob_diff(self, blob_name)
            if (is_initialized(self))
                res = caffe('get_blob_diff', blob_name);
            end
        end
        function res = get_all_data(self)
            if (is_initialized(self))
                res = caffe('get_all_data');
            end
        end
        function res = get_all_diff(self)
            if (is_initialized(self))
                res = caffe('get_all_diff');
            end
        end
        function res = get_init_key(self)
            res = caffe('get_init_key');
            assert(res==self.init_key);
        end
        function reset(self)
            caffe('reset');
            self.init_key = caffe('get_init_key');
        end
        function delete(self)
            reset(self);
            clear caffe;
        end
    end
end
