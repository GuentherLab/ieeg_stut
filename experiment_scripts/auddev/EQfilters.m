function varargout = EQfilters(option, varargin)
% EQFILTERS handles Audapter's equalization filters
% 
% EQfilters('set_audapter',FILTERCHANNEL, FILTERNAME)           sets audapter to use the specified equalization filter on its input or output channels
%       FILTERCHANNEL   : filter channel (valid channels: 'input' / 'output')
%       FILTERNAME      : filter name (valid filter names: 'S039' / 'S504' / 'MICMRI')
%
% EQfilters('set_audapter')                                     prompts user to select equalization filter(s) and sets audapter to use those filters
%
% EQfilters('apply',FILTERNAME, filename, output_filename)      applies specified filter to sample from audio file (filtered audio saved to file output_filename -EQfilters.wav if unspecified-)
%
% y = EQfilters('apply',FILTERNAME, x, fs)                      applies specified filter to audio sample vector x (returns audio sample vector y)
%
% [a,b] = EQfilters('parameters',FILTERNAME)                    returns filter parameters a&b (a*y = b*x IIR standard filter coefficients for signal @ 48KHz; see "help filter")
%

varargout=cell(1,nargout);
switch(lower(option))
    case 'parameters'  % SYNTAX: EQfilters('parameters', FILTERNAME)
        FILTERNAME=varargin{1};
        switch(lower(FILTERNAME))
            case {'s504','eqf_504'} % Sensimetrics EQF_504 headset (@scanner)
                a = [1 -5.75471474086736 15.9791443224195 -27.8453958746592 33.8679184114231 -31.3865228777312 25.3492709502468 -20.9153500856605 17.9606358134845 -14.8555875997507 12.3637115362324 -11.1903050536838 9.94268179949726 -7.71432259505361 5.60413356746172 -4.47470820603634 3.63628524621226 -2.38742427225541 1.08430775892996 -0.299453305156428 0.0383804002233832];
                b = 2.5882*[0.00570966595476346 -0.0112376169798971 0.0145754220683358 -0.0113190264529328 0.00644652023695776 -0.00365396238219983 0.00136510405311595 -0.00117107203692529 0.000170416836377158 2.10131851304439e-05 0.000131176108787179 -0.000742544816345201 0.00207734085707366 -0.0023577953561914 0.00677480722095782 -0.0118854702086538 0.0145060836128372 -0.0111439409018681 0.00491146766886396 -0.000997814774383153 -0.000235130515760644];
                varargout = {a,b};
            case {'s039','eqf_039'} % Sensimetrics EQF_039 headset (@lab)
                a = [1 -6.59489980575032 20.9024692844092 -41.4037840685715 56.5260387423997 -56.4441855693212 45.0482063375037 -34.5999389080782 30.018464073129 -26.2009413829119 19.6296006590608 -13.5637472846885 10.8126038632944 -9.08324444740378 5.67766183938254 -1.65366026611419 -0.63246266863126 0.892912575122782 -0.412466989820569 0.0918313902685314 -0.00756873987414437];
                b = 1.6998*[0.0127622766349562 -0.0431766797106021 0.0781967477235978 -0.0924120459361867 0.0779612001692361 -0.0535848526027319 0.0385456033017869 -0.0323125523771806 0.0207987122141989 -0.00081286144757852 -0.0167621192601555 0.0237450595777568 -0.0308165634833208 0.0530354157819125 -0.0817400118865043 0.0927925615117886 -0.0750555931117281 0.0428202185596123 -0.0165699830030819 0.00430091624292103 -0.000497270568656864];
                varargout = {a,b};
            case {'micmri','mrimic'} % MRI microphone
                a = [1 -9.52915144813273 45.1522962054778 -141.99191837284 334.429560946227 -632.158163078984 1003.40983818598 -1378.44787242915 1669.91933415235 -1801.82271589427 1738.4587797303 -1499.69500407391 1151.84104362081 -779.853545339674 457.352797812325 -226.292022769633 91.0816240723288 -28.3557158060592 6.33266694283288 -0.889341932820706 0.0575404393473084];
                b = 2.5148*[0.0143203767450595 -0.0947104784354571 0.315345313984227 -0.705196743263315 1.19090545074377 -1.61136108755349 1.7860984505105 -1.5889475271054 1.01221201672558 -0.196104662249616 -0.62087306168741 1.21042075776765 -1.44366965849317 1.32374458059306 -0.97182266456545 0.567387317174662 -0.255790548735093 0.0846932904521453 -0.0188856875240256 0.00235426222477005 -0.000101381212592431];
                varargout = {a,b};
            case 'none'
                varargout = {[], []}; 
            otherwise
                error('unknown filter %s (valid values: ''s039'', ''s504'', ''mrimic'', ''none'')',FILTERNAME);
        end
        
    case 'set_audapter', % SYNTAX: EQfilters('set_audapter' [, FILTERCHANNEL, FILTERNAME])
        if isempty(varargin)
            labelsInput={'none','MRImic (scanner microphone)'}; 
            optionInput={'none','MRImic'};
            labelsOutput={'none','S039 (lab Sensimetrics headphones)','S504 (scanner Sensimetrics headphones)'}; 
            optionOutput={'none','S039','S504'};
            thfig=figure('units','norm','position',[.4,.4,.35,.2],'color',1*[1 1 1],'name','Audapter input/output equalization filters','numbertitle','off','menubar','none');
            uicontrol('style','text','units','norm','position',[.1,.75,.8,.1],'string','Select input (microphone) filter','horizontalalignment','center','backgroundcolor',1*[1 1 1]);
            ht1=uicontrol('style','popupmenu','units','norm','position',[.1,.65,.8,.1],'string',labelsInput,'value',1,'backgroundcolor',1*[1 1 1],'tooltipstring','defines input equalization filter');
            uicontrol('style','text','units','norm','position',[.1,.45,.8,.1],'string','Select output (headphones) filter','horizontalalignment','center','backgroundcolor',1*[1 1 1]);
            ht2=uicontrol('style','popupmenu','units','norm','position',[.1,.35,.8,.1],'string',labelsOutput,'value',1,'backgroundcolor',1*[1 1 1],'tooltipstring','defines output equalization filter');
            uicontrol('style','pushbutton','string','OK','units','norm','position',[.1,.01,.38,.15],'callback','uiresume');
            uicontrol('style','pushbutton','string','Cancel','units','norm','position',[.51,.01,.38,.15],'callback','delete(gcbf)');
            uiwait(thfig);
            if ~ishandle(thfig), return; end
            optionInput=optionInput{get(ht1,'value')};
            optionOutput=optionOutput{get(ht2,'value')};
            EQfilters('set_audapter','input',optionInput);
            EQfilters('set_audapter','output',optionOutput);
            delete(thfig);
            varargout={optionInput,optionOutput};
        else
            FILTERCHANNEL=varargin{1};
            FILTERNAME=varargin{2};
            assert(ismember(lower(FILTERCHANNEL),{'input','output'}),'unknown filter type %s (valid values: ''input'', ''output'')');
            [a,b]=EQfilters('parameters',FILTERNAME);
            if isempty(a) % for 'none' option
                Audapter('setParam',sprintf('eqfilter%s',FILTERCHANNEL),0,0);
            else
                Audapter('setParam',sprintf('eqfilter%s',FILTERCHANNEL),1,0);
                Audapter('setParam',sprintf('eqfilter%s_a',FILTERCHANNEL),a, 0);
                Audapter('setParam',sprintf('eqfilter%s_b',FILTERCHANNEL),b, 0);
            end
        end
        
    case 'apply'
        FILTERNAME=varargin{1};
        x=varargin{2};
        if ischar(x), % SYNTAX: EQfilters('apply',FILTERNAME, filename [, output_filename]) 
            [x,fs]=audioread(x); 
            if numel(varargin)>=3&&~isempty(varargin{3}), fileout=varargin{3};
            else fileout=fullfile(pwd,'EQfilters.wav');
            end
        else          % SYNTAX: y = EQfilters('apply',FILTERNAME, x [, fs])
            if numel(varargin)>=3&&~isempty(varargin{3}), fs=varargin{3};
            else fs=48000;
            end
            fileout='';
        end
        if fs~=48000,
            [P,Q]=rat(48000/fs);
            x=resample(x,P,Q);
        end
        [a,b]=EQfilters('parameters',FILTERNAME);
        y=filter(b,a,x);
        if fs~=48000,
            y=resample(y,Q,P);
        end
        varargout = {y};
        if ~isempty(fileout), 
            audiowrite(fileout,y,fs);
            fprintf('Output filtered audio saved to %s',fileout);
        end
            
        
    otherwise
        error('unknown option %s',option);
end
