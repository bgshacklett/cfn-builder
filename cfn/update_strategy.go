package cfn

import (
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
)

// TemplateUpdateStrategy defines an interface for functions which
// intend to update CloudFormation templates from a live environment.
type TemplateUpdateStrategy interface {
	Execute(

		region string,
		template *cloudformation.Template,
		stackName string,
		cfnMapper aws.CfnMapper,
		resourceDescriber aws.ResourceDescriber,

	) (*cloudformation.Template, error)
}

// DefaultUpdateStrategy currently returns a bogus string on execution.
type DefaultUpdateStrategy struct{}

// Execute implements the Execute
func (r *DefaultUpdateStrategy) Execute(

	region string,
	template *cloudformation.Template,
	stackName string,
	cfnMapper aws.CfnMapper,
	resourceDescriber aws.ResourceDescriber,

) (*cloudformation.Template, error) {

	return new(cloudformation.Template), nil
}
