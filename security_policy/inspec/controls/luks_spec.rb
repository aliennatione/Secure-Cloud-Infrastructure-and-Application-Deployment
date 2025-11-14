# encoding: utf-8
# copyright: 2025

title 'LUKS Encryption Compliance'

control 'luks-01' do
  impact 1.0
  title 'LUKS encryption properly configured'
  desc 'Ensure LUKS encryption is properly set up on the secure volume'
  
  describe file('/etc/crypttab') do
    it { should exist }
    its('content') { should match /cryptroot/ }
    its('content') { should match /luks/ }
    its('mode') { should cmp '0600' }
  end
  
  describe command('cryptsetup status cryptroot') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /type:\s+LUKS2/ }
    its('stdout') { should match /cipher:\s+aes-xts-plain64/ }
  end
  
  describe mount('/mnt/secure') do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/cryptroot' }
    its('type') { should eq 'ext4' }
    its('options') { should include 'rw' }
  end
end

control 'luks-02' do
  impact 0.8
  title 'Dropbear configured for remote unlock'
  desc 'Ensure Dropbear is properly configured for remote LUKS unlock'
  
  describe package('dropbear-initramfs') do
    it { should be_installed }
  end
  
  describe file('/etc/dropbear-initramfs/authorized_keys') do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('size') { should be > 0 }
  end
  
  describe file('/etc/initramfs-tools/hooks/unlock_script') do
    it { should exist }
    its('mode') { should cmp '0755' }
  end
  
  describe command('lsinitramfs /boot/initrd.img-* | grep dropbear') do
    its('exit_status') { should eq 0 }
  end
end
