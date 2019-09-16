%{
PostProcessStressData_func.m

Last updated: 02/04/2010

adapted from the code by Pat Alfred by Anya Grosberg
Disease Biophysics Group
School of Engineering and Applied Sciences
Havard University, Cambridge, MA 02138

The purpose of this function is to analyze the stress data generated by FilmStressCalcMainMulti for each file fed in by





Input: 1. file and path name for the current file

Output:
%}

function [filt_stress,basal_stress,mean_rise_time,mean_fall_time,mean_peak_cont_stress,cont_stress,num_films,mean_freq,pre_stress,abs_max_stress] = PostProcessStressData_func(fileX,pathX,order_filter,Cutoff_freq)

path_and_file=[pathX fileX] ;
%load the file into a data variable
data=load(path_and_file);

FilmStress=data.FilmStress; %stress in num_films films as a function of time
time_temp = data.time;  %time vector generated during stress/xproj calculations
%ignore the last time point because it has always stress at zero - an artifact of data aquisition
time = time_temp(1:(length(time_temp)-1));
num_films=data.num_films; %number of films
frame_rate=data.frame_rate; %frame rate of the original movie
t=(1:1:length(time))'; %time counter

sys_i=[];
sys_stress=[];
dys_i=[];
dys_stress=[];

for filmcount=1:num_films %cycle through each film
    %asign a single film stress to the cell_stress function, ignore the
    %last time point because it has always stress at zero - an artifact of
    %data aquisition
    cell_stress=FilmStress(1:length(time),filmcount); %stress for the specific film
    cell_stress=(cell_stress>0).*cell_stress; %take only positive stress, set others to zero

    %set the startpoint of the analysis for the second time point, and end
    %two prior - this is dones to simplify calculations and does not impact
    %analysis.
    startpoint=2;
    endpoint=length(time)-2;
    
    %Generate the filter
    [b,a]=butter(order_filter,Cutoff_freq);
    %Filter out the noise from the data
    new_stress=filtfilt(b,a,cell_stress);
    abs_min = min(new_stress); %absolute minimum
    abs_max = max(new_stress); %absolute maximum
    abs_stroke = (abs_max - abs_min); %absolute stroke
    min_stroke = 0.2*abs_stroke; %The distance between max and min has to be at least this for them to count
    mid_point = abs_min + abs_stroke/2; %mid point
    
    %initilize count variables
    count_ext=0; %count the number of extrema
    count_sys=0; %count number of peak systole (i.e. maximal stress)
    count_dys=0; %count number of minimums
    ext_type = 0;

    %The diffstress is the difference between
    %new_stress(i+1)-new_stress(i), i.e. it is negative in decreasing
    %sections and positive in increasing
    diffstress=diff(new_stress);

   %cycle through the relevant time points
    for i=startpoint:endpoint
        
        %If diffstress(i) >=0 and diffstress(i-1)<0 there is a minimum
        %either at i or in between i and i-1, estimate that it is at i
        if diffstress(i)>=0 && diffstress(i-1)<0
            %increase the counter of the extrema 
            count_ext=count_ext+1;

            %Store the stress value at the extremum
            ext_val(count_ext)=new_stress(i);
            %store the placement of the extremum
            ext_i(count_ext)=i;
            %record the extrema type 0 - minima, 1 - maxima -- assume the
            %extrema is of the type of the previous, unless it is reset
            %later in the loop
            if count_ext > 1
                ext_type(count_ext) = ext_type(count_ext-1);
            end
            
            if count_sys > 0 %if there is a maximum before we enter this loop, then check the differences.
                if ext_type(count_ext-1)==0 %if the previous extrema was a minimum
                    %switch to whichever is smaller
                    if ext_val(count_ext) < dys_stress(count_dys)
                        %count_dys = count_dys;
                        %store the value of the placement of a minimum
                        dys_i(count_dys)=ext_i(count_ext);
                        %store the value of the minimal stress
                        dys_stress(count_dys)=ext_val(count_ext);
                        %record the extrema type 0 - minima, 1 - maxima
                        ext_type(count_ext) = 0;
                    end %if the previous was smaller leave it as is
                else %if the previous was a minima continue
                    if abs(ext_val(count_ext)-ext_val(count_ext-1)) > min_stroke %check that the difference is greater than the minimal stroke
                        %increase the counter of end systole to include the new minimum
                        count_dys=count_dys+1;
                        %store the value of the placement of a minimum
                        dys_i(count_dys)=ext_i(count_ext);
                        %store the value of the minimal stress
                        dys_stress(count_dys)=ext_val(count_ext);
                        %record the extrema type 0 - minima, 1 - maxima
                        ext_type(count_ext) = 0;
                    else if (count_dys > 1) && (dys_stress(count_dys) > ext_val(count_ext)) %if this is at least the second min and the previous maximum wasn't high enough we need to check that the previous minimum wasn't greater than this one
                            %if the new minimum is smaller update it without increasing the minimum count
                            %store the value of the placement of a minimum
                            dys_i(count_dys)=ext_i(count_ext);
                            %store the value of the minimal stress
                            dys_stress(count_dys)=ext_val(count_ext);
                            %record the extrema type 0 - minima, 1 - maxima
                            ext_type(count_ext) = 0;
                        end
                    end
                end
            else if (ext_val(count_ext)< mid_point) %else make sure it is actually a minimum and that we don't generate multiple minimums in the beginning
                    if count_dys > 0 %this is the second identified minimum, while no maximums have been identified and it is smaller than the previous one
                        if dys_stress(count_dys) > ext_val(count_ext)
                            %store the value of the placement of a minimum
                            dys_i(count_dys)=ext_i(count_ext);
                            %store the value of the minimal stress
                            dys_stress(count_dys)=ext_val(count_ext);
                            %record the extrema type 0 - minima, 1 - maxima
                            ext_type(count_ext) = 0;
                        end
                    else
                        %increase the counter of end systole to include the new minimum
                        count_dys=count_dys+1;
                        %store the value of the placement of a minimum
                        dys_i(count_dys)=ext_i(count_ext);
                        %store the value of the minimal stress
                        dys_stress(count_dys)=ext_val(count_ext);
                        %record the extrema type 0 - minima, 1 - maxima
                        ext_type(count_ext) = 0;
                    end
                end
            end

        end
        %If diffstress(i) <=0 and diffstress(i-1)>0 there is a maximum
        %either at i or in between i and i-1, estimate that it is at i
        if diffstress(i)<=0 && diffstress(i-1)>0
            %increase the counter of the extrema 
            count_ext=count_ext+1;
                      
            %Store the stress value at the extremum
            ext_val(count_ext)=new_stress(i);
            %store the placement of the extremum
            ext_i(count_ext)=i;
            
            %record the extrema type 0 - minima, 1 - maxima -- assume the
            %extrema is of the type of the previous, unless it is reset
            %later in the loop
            if count_ext > 1
                ext_type(count_ext) = ext_type(count_ext-1);
            end
            
            if count_dys > 0 %if this was a minimum before this check the differences
                if ext_type(count_ext-1)==1 %if the previous extrema was a maximum
                    %switch to whichever is bigger
                    if ext_val(count_ext) > sys_stress(count_sys)
                        %count_sys = count_sys;
                        %store the value of the placement of a maximum
                        sys_i(count_sys)=ext_i(count_ext);
                        %store the value of the maximal stress
                        sys_stress(count_sys)=ext_val(count_ext);
                        %record the extrema type 0 - minima, 1 - maxima
                        ext_type(count_ext) = 1;
                    end %if the previous was bigger leave it as is
                else %if the previous was a minima continue
                    if abs(ext_val(count_ext)-ext_val(count_ext-1)) > min_stroke %check that the difference is greater than the minimal stroke
                        %increase the counter of and end systole to include
                        %the new maximum
                        count_sys=count_sys+1;
                        %store the value of the placement of a maximum
                        sys_i(count_sys)=ext_i(count_ext);
                        %store the value of the maximal stress
                        sys_stress(count_sys)=ext_val(count_ext);
                        %record the extrema type 0 - minima, 1 - maxima
                        ext_type(count_ext) = 1;
                    else if (count_sys > 1) && (sys_stress(count_sys) < ext_val(count_ext)) %if this is at least the second max and the previous min wasn't high enough we need to check that the previous max wasn't greater than this one
                            %if the new minimum is smaller update it without increasing the minimum count
                            %store the value of the placement of a maximum
                            sys_i(count_sys)=ext_i(count_ext);
                            %store the value of the maximal stress
                            sys_stress(count_sys)=ext_val(count_ext);
                            %record the extrema type 0 - minima, 1 - maxima
                            ext_type(count_ext) = 1;
                        end
                    end
                end
            else if (ext_val(count_ext)> mid_point) %else make sure it is actually a maximum
                    if count_sys > 0 %this is the second identified maximum, while no minimums have been identified and it is smaller than the previous one
                        if sys_stress(count_sys) < ext_val(count_ext)
                            %store the value of the placement of a minimum
                            sys_i(count_sys)=ext_i(count_ext);
                            %store the value of the minimal stress
                            sys_stress(count_sys)=ext_val(count_ext);
                            %record the extrema type 0 - minima, 1 - maxima
                            ext_type(count_ext) = 1;
                        end
                    else                        
                        %increase the counter of and end systole to include
                        %the new maximum
                        count_sys=count_sys+1;
                        %store the value of the placement of a maximum
                        sys_i(count_sys)=ext_i(count_ext);
                        %store the value of the maximal stress
                        sys_stress(count_sys)=ext_val(count_ext);
                        %record the extrema type 0 - minima, 1 - maxima
                        ext_type(count_ext) = 1;
                    end
                end
            end
        end

            
        
    end
    
    figure(filmcount)
    hold on
    subplot(2,1,1)
    plot(t(1:end),new_stress,sys_i,sys_stress,'o',dys_i,dys_stress,'*')
    subplot(2,1,2)
    plot(t(1:end),cell_stress,t(1:end),new_stress,'r')
    
    %Determine if a maximum (peak systole) was first or a minimum (min dys)
    %put in fail safes for non-data films
    if count_sys > count_dys+1
        count_sys = count_dys+1;
    end
    if count_dys > count_sys+1
        count_dys = count_sys+1;
    end
    if numel(sys_i)==0 || numel(dys_i)==0
        fall_time=[];
        rise_time=[];
        peak_cont_stress=[];
    else
        if sys_i(1)< dys_i(1)
            end_of_count = min(count_dys,count_sys);
            %fall time
            fall_time = dys_i(1:end_of_count) - sys_i(1:end_of_count);
            %rise time
            rise_time = sys_i(2:end_of_count) - dys_i(1:(end_of_count-1));
            %peak contraction stress
            peak_cont_stress = sys_stress(2:end_of_count) - dys_stress(1:(end_of_count-1));
        else %if the minimum was first
            end_of_count = min(count_dys,count_sys);
            %fall time
            fall_time = dys_i(2:end_of_count) - sys_i(1:(end_of_count-1));
            %rise time
            rise_time = sys_i(1:end_of_count) - dys_i(1:end_of_count);
            %peak contraction stress
            peak_cont_stress = sys_stress(1:end_of_count) - dys_stress(1:end_of_count);
        end
    end
    %period for each peak
    period = diff(dys_i);
    %frequency at each peak
    freq = 1./period;

    figure(filmcount)
    hold on
    subplot(2,1,1)
    plot(t(1:end),new_stress,sys_i,sys_stress,'o',dys_i,dys_stress,'*')
    subplot(2,1,2)
    plot(t(1:end),cell_stress,t(1:end),new_stress,'r')

    sys_stress
    %basal stress - the minimum of the minima extrema
    basal_stress(filmcount)=min(dys_stress);
    %pre-stress - the average of end diastole stress
    pre_stress(filmcount) = mean(dys_stress);
    %maximal stress - absolute
    abs_max_stress(filmcount) = mean(sys_stress);
    %average rise time in time units
    mean_rise_time(filmcount)=mean(rise_time)./frame_rate;
    %average fall time in time units
    mean_fall_time(filmcount)=mean(fall_time)./frame_rate;
    %average peak contraction stress
    mean_peak_cont_stress(filmcount)=mean(peak_cont_stress);
    %Normalized stress
    cont_stress(:,filmcount)=new_stress - basal_stress(filmcount).*ones(size(new_stress));
    %Filtered stress
    filt_stress(:,filmcount)=new_stress;
    %Mean frequency - should match pacing frequency
    mean_freq(filmcount) = mean(freq).*frame_rate;
    
    clear sys_stress sys_i dys_stress dys_i ext_val ext_i

end
hold off
filename_analyzed=[pathX fileX(1:(length(fileX)-4)) '_analyzed.mat'];
save(filename_analyzed,'FilmStress','time','num_films','frame_rate','path_and_file','basal_stress','mean_rise_time','mean_fall_time','mean_peak_cont_stress','cont_stress','mean_freq','pre_stress','abs_max_stress','filt_stress')