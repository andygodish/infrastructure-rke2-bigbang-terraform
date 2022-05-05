# BigBang Test Environment

## Commands

aws s3 cp s3://bb-dev-andyg-lkq-rke2/rke2.yaml ~/.kube/config

sshuttle -vr bb_bastion --dns 10.0.0.0/16 --ssh-cmd 'ssh -i ~/.ssh/bb-dev-andyg-lkq-rke2.pem'

```
export CNAME="bb-dev-andyg"

export BSG=`aws ec2 describe-instances --filters "Name=tag:Name,Values=$CNAME-bastion" --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text`

export MYIP=`curl -s http://checkip.amazonaws.com/`

aws ec2 authorize-security-group-ingress --group-id $BSG --protocol tcp --port 22 --cidr $MYIP/32

export BIP=`aws ec2 describe-instances --filters "Name=tag:Name,Values=$CNAME-bastion" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text`

sshuttle --dns -vr ec2-user@$BIP 10.0.0.0/8 --ssh-cmd "ssh -i ~/.ssh/$CNAME.pem"

kubectl get no
```

## Prereqs to BB Installation

#### GPG

```
gpg --batch --full-generate-key --rfc4880 --digest-algo sha512 --cert-digest-algo sha512 <<EOF
    %no-protection
    # %no-protection: means the private key won't be password protected
    # (no password is a fluxcd requirement, it might also be true for argo & sops)
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Expire-Date: 0
    Name-Real: bigbang-dev-environment
    Name-Comment: bigbang-dev-environment
EOF
```
```
# The following command will store the GPG Key's Fingerprint in the $fp variable
# (The following command has been verified to work consistently between multiple versions of gpg: 2.0.x, 2.2.x, 2.3.x)
export fp=$(gpg --list-keys --fingerprint | grep "bigbang-dev-environment" -B 1 | grep -v "bigbang-dev-environment" | tr -d ' ' | tr -d 'Keyfingerprint=')
echo $fp

# Key will now expire after 1 yr
gpg --quick-set-expire ${fp} 1y

# Different command for linux
sed -i "" "s/pgp: FALSE_KEY_HERE/pgp: ${fp}/" .sops.yaml
```