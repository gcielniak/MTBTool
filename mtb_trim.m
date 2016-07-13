function mtb_trim(file_name,trim_begin,trim_end)%mtb file trimmer

if nargin == 1
    trim_begin = 0;
elseif nargin == 2
    trim_end = 0;
end

file_name_out = [file_name(1:end-4) '_trimmed.mtb'];

fid = fopen(file_name);
fid_out = fopen(file_name_out,'w+');

if fid == -1
    fprintf('Could not open %s file.',file_name);
    return;
end

if fid_out == -1
    fprintf('Could not create %s file.',file_name_out);
    return;
end

packet_counter = 0;
packet_begin = 0;
packet_end = 0;

while ~feof(fid)
    preamble = fread(fid,1);
    if preamble == 250 % 0xFA        
        bid = fread(fid,1);
        if bid == 255 % 0xFF
            mid = fread(fid,1);
            length = fread(fid,1);
            if length == 255
                length_ext = fread(fid,2);
                length = length_ext(1) * 256 + length_ext(2);
            end
            data = fread(fid,length);
            if 0
            if mid == 13
                date = char(data(17:24));
                time = char(data(25:32));
            elseif mid == 54
                jj = 1;
                while jj < size(data,1)
                    did = data(jj)*256 + data(jj+1);
                    jj = jj+2;
                    dlength = data(jj);
                    if did == 4128 % 0x1020
                        packet_end = data(jj+1)*256+data(jj+2);
                        if packet_begin == 0
                            packet_begin = packet_end;
                        end
                        fprintf('Packet counter %d\n',packet_end);
                    elseif did == 4112 % 0x1010
                        ns = data(jj+1)*256*256*256 + data(jj+2)*256*256 + data(jj+3)*256 + data(jj+4);
                        year = data(jj+5)*256 + data(jj+6);
                        month = data(jj+7);     
                        day = data(jj+8);
                        hour = data(jj+9);                        
                        minute = data(jj+10);
                        second = data(jj+11);
                        fprintf('UTC time %04d%02d%02dT%02d%02d%02d:%09d\n',year,month,day,hour,minute,second,ns);
                    elseif did == 4192 % 0x1060
                        time_fine = data(jj+1)*256*256*256 + data(jj+2)*256*256 + data(jj+3)*256 + data(jj+4);
                        fprintf('SampleTimeFine %d\n',time_fine);
                    elseif did == 4108 % 0x1070
                        time_coarse = data(jj+1)*256*256*256 + data(jj+2)*256*256 + data(jj+3)*256 + data(jj+4);
                        fprintf('SampleTimeCoarse %d\n',time_coarse);
                    end
                    jj = jj+1+dlength;
                end
            end
            end
            checksum = fread(fid,1);
            %fprintf('Message: mid %d, length %d\n',mid,length);
            
            if mid == 54
                packet_counter = packet_counter + 1;
                if packet_counter <= trim_begin
                    continue;
                end
                if trim_end ~= 0 && packet_counter > trim_end
                    continue;
                end
            end
            
            %%write message
            fwrite(fid_out,[preamble bid mid]);
            if length >= 255
                fwrite(fid_out,[255 length/256 mod(length,256)]);
            else
                fwrite(fid_out,length);
            end
            fwrite(fid_out,data);
            fwrite(fid_out,checksum);
        end
    end
end

fclose(fid);
fclose(fid_out);

