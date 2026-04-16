function outblk = aes128_encrypt_block(inblk, key)
% 单块AES128加密，输入inblk/key均为1×16 uint8
% 复用本工程的核心AES脚本与子函数

AESType = "128-bit";
keyType = "Plaintext";  % 按你项目key格式决定（常为"Hex"或"Plaintext"）
% 以"Hex"举例，若实际key格式为ASCII，则应调整为"ASCII"

% 1. 生成所有轮密钥
allKeys = key_creation(key, keyType, AESType);  % 4x(N) string

% 2. 数据格式转string并reshape，兼容key扩展模块接口
if ischar(inblk)
    inblk = uint8(hex2dec(reshape(inblk,2,[]))');
elseif isnumeric(inblk) && size(inblk,1)==1
    inblk = uint8(inblk(:));
end

state = string(dec2hex(inblk));  % 16x1 string十六进制

numbRounds = 10;     % 128-bit AES为10轮

% 3. 逐步执行标准AES主流程(仅一块)
roundKeyOutput = add_round_key(state, allKeys(:,1));
for rounds = 2:numbRounds
    subByteOutput = sub_byte(roundKeyOutput, "encrypt");
    shiftRowOutput = shift_row(subByteOutput, "encrypt");
    mixColumnOutput = mix_column(shiftRowOutput, "encrypt");
    roundKeyOutput = add_round_key(mixColumnOutput, allKeys(:,rounds));
end
subByteOutput = sub_byte(roundKeyOutput, "encrypt");
shiftRowOutput = shift_row(subByteOutput, "encrypt");
roundKeyOutput = add_round_key(shiftRowOutput, allKeys(:,numbRounds+1));

% 4. 输出uint8格式密文块
outblk = uint8(hex2dec(roundKeyOutput));  % 16x1 uint8
outblk = outblk(:)';  % 输出1×16
% outblk = inblk;
end