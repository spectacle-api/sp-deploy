const aws = require('@pulumi/aws');
const awsx = require('@pulumi/awsx');
const pulumi = require('@pulumi/pulumi');

const size = 't4g.nano';
const ami = aws.ec2.getAmiOutput({
  filters: [
    {
      name: 'name',
      values: ['ubuntu/images/*22.04*arm64*server*'],
    },
  ],
  owners: ['099720109477'],
  mostRecent: true,
});

const vpc = aws.ec2.getVpcOutput({ tags: { Name: 'prod' } });
const subnet = aws.ec2.getSubnetOutput({
  vpcId: vpc.id,
  tags: { Name: 'prod-public-1' },
});

const group = new aws.ec2.SecurityGroup('jump', {
  description: 'Jump Host',
  vpcId: vpc.id,
  ingress: [
    {
      description: 'ssh',
      fromPort: 22,
      toPort: 22,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'],
      ipv6CidrBlocks: ['::/0'],
    },
    {
      description: 'openvpn-tcp',
      fromPort: 443,
      toPort: 443,
      protocol: 'tcp',
      cidrBlocks: ['0.0.0.0/0'],
      ipv6CidrBlocks: ['::/0'],
    },
    {
      description: 'openvpn-udp',
      fromPort: 1194,
      toPort: 1194,
      protocol: 'udp',
      cidrBlocks: ['0.0.0.0/0'],
      ipv6CidrBlocks: ['::/0'],
    },
  ],
  egress: [
    {
      fromPort: 0,
      toPort: 0,
      protocol: '-1',
      cidrBlocks: ['0.0.0.0/0'],
      ipv6CidrBlocks: ['::/0'],
    },
  ],
  tags: {
    Name: 'jump',
  },
});

const server = new aws.ec2.Instance('jump', {
  instanceType: size,
  vpcSecurityGroupIds: [group.id],
  ami: ami.id,
  subnetId: subnet.id,
  tags: {
    Name: 'jump',
  },
  rootBlockDevice: {
    volumeType: 'gp3',
  },
  keyName: 'jlake',
});

const eip = new aws.ec2.Eip('jump-eip', {
  instance: server.id,
  vpc: true,
  tags: {
    Name: 'jump-eip',
  },
});
