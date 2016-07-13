%mtb file cutter

file_name = 'H:\data\Murcia Broccoli Data 25-29 April 2016\Documents\MT_07700741_029.mtb';
file_name = 'H:\data\MT_07700741_011.mtb';

fid = fopen(file_name);

if fid == -1
    fprintf('Could not open %s file.',file_name);
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
            checksum = fread(fid,1);
            fprintf('Message: mid %d, length %d\n',mid,length);            
            packet_counter = packet_counter + 1;
        end
    end
end

fclose(fid);

packet_counter
packet_begin
packet_end
