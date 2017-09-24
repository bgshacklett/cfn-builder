package cfn

import (
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
)

// TemplateUpdateStrategy defines an interface for functions which
// intend to update CloudFormation templates from a live environment.
type TemplateUpdateStrategy interface {
	Execute(
		template cloudformation.Template,
		stackName string,
		region string,
		resourceDescriber ResourceDescriber,
	) (interface{}, error)
}

// DefaultUpdateStrategy currently returns a bogus string on execution.
type DefaultUpdateStrategy struct{}

// Execute implements the Execute
func (r *DefaultUpdateStrategy) Execute(
	template cloudformation.Template,
	stackName string,
	region string,
	resourceDescriber ResourceDescriber,

) (interface{}, error) {

	return "Default Update Strategy", nil
}
