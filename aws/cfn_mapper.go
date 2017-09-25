package aws

import (
	"github.com/aws/aws-sdk-go/aws/arn"
)

type CfnMapper interface {
	MapResource(
		region string,
		stackName string,
		resource string,
	) (arn.ARN, error)
}
