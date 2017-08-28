package cfn

// TemplateUpdateStrategy defines a function interface for functions which
// intend to update CloudFormation templates from a live environment.
type TemplateUpdateStrategy func(

	path string,
	stackName string,
	region string,

) (interface{}, error)

// DefaultUpdateStrategy currently returns a bogus string.
var DefaultUpdateStrategy TemplateUpdateStrategy = func(

	path string,
	stackName string,
	region string,

) (interface{}, error) {

	return "Default Update Strategy", nil
}
