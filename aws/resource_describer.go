package aws

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/bgshacklett/extropy/frames"
	"github.com/aws/aws-sdk-go/service/ec2"

)

// ResourceDescriber
type ResourceDescriber struct{
	Description interface{}
}



func (r *ResourceDescriber) DescribeResource(resource frames.SupportedResource, region string) error {

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		return err
	}

	switch resource.ResourceType {
	case "AWS::EC2::SecurityGroup":

		svc := ec2.New(sess)

		//noinspection GoUnresolvedReference - goland garbage :(
		result, err := svc.DescribeSecurityGroups(&ec2.DescribeSecurityGroupsInput{
			GroupIds: []*string{aws.String(resource.PhysicalResourceId)},
		})

		if err != nil {
			return err
		}

		//noinspection GoUnresolvedReference - goland garbo
		r.Description = result.SecurityGroups[0]

	default:

	}

	return nil
}
