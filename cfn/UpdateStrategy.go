package cfn

// TemplateUpdateStrategy defines an interface for functions which
// intend to update CloudFormation templates from a live environment.
type TemplateUpdateStrategy interface {
	Execute(path string, stackName string, region string) (interface{}, error)
}

// DefaultUpdateStrategy currently returns a bogus string.
type DefaultUpdateStrategy struct{}

func (self *DefaultUpdateStrategy) Execute(
	path string,
	stackName string,
	region string,
) (interface{}, error) {

	return "Default Update Strategy", nil
}
