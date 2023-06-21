const aws = require('@pulumi/aws');
const awsx = require('@pulumi/awsx');
const pulumi = require('@pulumi/pulumi');

const { CODE_BUCKET } = require('../../config');

const email = new aws.iam.Policy('ses-send-email', {
  path: '/',
  name: 'ses-send-email',
  description: 'ses-send-email',
  policy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Action: ['ses:SendEmail', 'ses:SendRawEmail'],
        Resource: '*',
      },
    ],
  }),
});
const server_control = new aws.iam.Policy('server-control', {
  path: '/',
  name: 'server-control',
  description: 'server-control',
  policy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Action: ['ec2:DescribeInstances'],
        Resource: ['*'],
      },
      {
        Effect: 'Allow',
        Action: [
          'ec2:DescribeLaunchTemplateVersions',
          'ec2:ModifyLaunchTemplate',
          'ec2:CreateLaunchTemplateVersion',
        ],
        Resource: ['*'],
      },
      {
        Effect: 'Allow',
        Action: ['autoscaling:DescribeAutoScalingGroups'],
        Resource: ['*'],
      },
    ],
  }),
});
new aws.iam.Policy('s3-code-push', {
  path: '/',
  name: 's3-code-push',
  description: 's3-code-push',
  policy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Action: ['s3:ListBucket'],
        Resource: [`arn:aws:s3:::${CODE_BUCKET}`],
      },
      {
        Effect: 'Allow',
        Action: ['s3:PutObject', 's3:GetObject'],
        Resource: [`arn:aws:s3:::${CODE_BUCKET}/*`],
      },
    ],
  }),
});
const code_read = new aws.iam.Policy('s3-code-read', {
  path: '/',
  name: 's3-code-read',
  description: 's3-code-read',
  policy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Action: 's3:GetObject',
        Resource: `arn:aws:s3:::${CODE_BUCKET}/*`,
      },
      {
        Effect: 'Allow',
        Action: 's3:ListBucket',
        Resource: `arn:aws:s3:::${CODE_BUCKET}`,
      },
    ],
  }),
});

const role = new aws.iam.Role('sp-api-prod', {
  name: 'sp-api-prod',
  description: 'sp-api-prod',
  path: "/",
  assumeRolePolicy: '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}',
  managedPolicyArns: [code_read.arn, server_control.arn, email.arn],
});
new aws.iam.InstanceProfile("sp-api-prod", {
  name: 'sp-api-prod',
  role: role.name
});

