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

const group = new aws.ec2.SecurityGroup('admin-tools', {
  description: 'Admin Tools',
  vpcId: vpc.id,
  ingress: [
    {
      description: 'ssh',
      fromPort: 22,
      toPort: 22,
      protocol: 'tcp',
      cidrBlocks: [vpc.cidrBlock],
    },
    {
      description: 'http',
      fromPort: 80,
      toPort: 80,
      protocol: 'tcp',
      cidrBlocks: [vpc.cidrBlock],
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
    Name: 'admin-tools',
  },
});

const server = new aws.ec2.Instance('admin-tools', {
  instanceType: size,
  vpcSecurityGroupIds: [group.id],
  subnetId: subnet.id,
  ami: ami.id,
  tags: {
    Name: 'admin-tools',
  },
  keyName: 'jlake',
  rootBlockDevice: {
    volumeType: 'gp3',
  },
});
