function out = gcm_pad(in)
% 按16字节block对齐并补0
if mod(numel(in),16)==0
    out = in;
else
    out = [in, zeros(1, 16-mod(numel(in),16),'uint8')];
end
end