% Simple OFDM Simulation with QPSK
no_of_data_bits = 64;          % Number of symbols
M = 4;                         % QPSK modulation
block_size = 16;               % IFFT size
cp_len = floor(0.1 * block_size); % Cyclic prefix length

% Generate random data
data = randsrc(1, no_of_data_bits, 0:M-1);
figure(1), stem(data); title('Original Data'); grid on;

% QPSK Modulation
qpsk_modulated_data = pskmod(data, M);
figure(2), stem(qpsk_modulated_data); title('QPSK Modulated Data');

% Serial to Parallel (4 subcarriers)
S2P = reshape(qpsk_modulated_data, no_of_data_bits/M, M);
Sub_carrier1 = S2P(:,1); Sub_carrier2 = S2P(:,2);
Sub_carrier3 = S2P(:,3); Sub_carrier4 = S2P(:,4);
figure(3)
subplot(4,1,1), stem(Sub_carrier1), title('Subcarrier 1')
subplot(4,1,2), stem(Sub_carrier2), title('Subcarrier 2')
subplot(4,1,3), stem(Sub_carrier3), title('Subcarrier 3')
subplot(4,1,4), stem(Sub_carrier4), title('Subcarrier 4')

% IFFT
number_of_subcarriers = 4;
cp_start = block_size - cp_len;
ifft_Subcarrier1 = ifft(Sub_carrier1, block_size);
ifft_Subcarrier2 = ifft(Sub_carrier2, block_size);
ifft_Subcarrier3 = ifft(Sub_carrier3, block_size);
ifft_Subcarrier4 = ifft(Sub_carrier4, block_size);
figure(4)
subplot(4,1,1), plot(real(ifft_Subcarrier1),'r'), title('IFFT Output Subcarrier 1')
subplot(4,1,2), plot(real(ifft_Subcarrier2),'c')
subplot(4,1,3), plot(real(ifft_Subcarrier3),'b')
subplot(4,1,4), plot(real(ifft_Subcarrier4),'g')

% Add Cyclic Prefix
for i=1:number_of_subcarriers
    ifft_Subcarrier(:,i) = ifft(S2P(:,i), block_size);
    for j=1:cp_len
        cyclic_prefix(j,i) = ifft_Subcarrier(j+cp_start,i);
    end
    Append_prefix(:,i) = [cyclic_prefix(:,i); ifft_Subcarrier(:,i)];
end
A1=Append_prefix(:,1); A2=Append_prefix(:,2);
A3=Append_prefix(:,3); A4=Append_prefix(:,4);
figure(5)
subplot(4,1,1), plot(real(A1),'r'), title('Cyclic Prefix Added Subcarrier 1')
subplot(4,1,2), plot(real(A2),'c')
subplot(4,1,3), plot(real(A3),'b')
subplot(4,1,4), plot(real(A4),'g')

% Serialize for transmission
[rows_Append_prefix, cols_Append_prefix] = size(Append_prefix);
ofdm_signal = reshape(Append_prefix, 1, rows_Append_prefix*cols_Append_prefix);
figure(6), plot(real(ofdm_signal)); title('OFDM Transmit Signal'); grid on;

% Channel + AWGN
channel = randn(1,2) + 1j*randn(1,2);
after_channel = filter(channel, 1, ofdm_signal);
recvd_signal = awgn(after_channel, 15, 'measured');
figure(7), plot(real(recvd_signal)); title('Received Signal with Noise'); grid on;

% Parallelize
recvd_signal_par = reshape(recvd_signal, rows_Append_prefix, cols_Append_prefix);

% Remove Cyclic Prefix
recvd_signal_par(1:cp_len,:) = [];
R1=recvd_signal_par(:,1); R2=recvd_signal_par(:,2);
R3=recvd_signal_par(:,3); R4=recvd_signal_par(:,4);
figure(8)
subplot(4,1,1), plot(real(R1),'r'), title('After CP Removal - Subcarrier 1')
subplot(4,1,2), plot(real(R2),'c')
subplot(4,1,3), plot(real(R3),'b')
subplot(4,1,4), plot(real(R4),'g')

% FFT (Demodulation)
for i=1:number_of_subcarriers
    fft_data(:,i) = fft(recvd_signal_par(:,i), block_size);
end
F1=fft_data(:,1); F2=fft_data(:,2); F3=fft_data(:,3); F4=fft_data(:,4);
figure(9)
subplot(4,1,1), plot(real(F1),'r'), title('FFT Output Subcarrier 1')
subplot(4,1,2), plot(real(F2),'c')
subplot(4,1,3), plot(real(F3),'b')
subplot(4,1,4), plot(real(F4),'g')

% Serial + Demodulation
recvd_serial_data = reshape(fft_data, 1, []);
qpsk_demodulated_data = pskdemod(recvd_serial_data, M);
figure(10)
stem(data,'bo'); hold on; stem(qpsk_demodulated_data,'rx');
legend('Transmitted','Received'); title('Recovered Data'); grid on;
