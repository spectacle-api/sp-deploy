const aws = require('@pulumi/aws');
const awsx = require('@pulumi/awsx');
const pulumi = require('@pulumi/pulumi');

const { VPC_CIDR } = require('../../config');

const vpc = new awsx.ec2.Vpc('prod', {
  cidrBlock: VPC_CIDR,
  numberOfAvailabilityZones: 3,
  subnetSpecs: [
    {
      name: 'elb',
      type: awsx.ec2.SubnetType.Public,
      cidrMask: 24,
    },
    {
      name: 'public',
      type: awsx.ec2.SubnetType.Public,
      cidrMask: 24,
    },
    {
      name: 'private',
      type: awsx.ec2.SubnetType.Isolated,
      cidrMask: 24,
    },
  ],
  natGateways: {
    strategy: 'None',
  },
});
