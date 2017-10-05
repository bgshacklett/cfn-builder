package cfn

import (
	"github.com/bgshacklett/extropy/aws"
)

// A ResourceBuilder builds CloudFormation Resources
type ResourceBuilder interface {
	Build(aws.Resource) (Resource, error)
}
