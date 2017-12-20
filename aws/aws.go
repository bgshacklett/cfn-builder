// Package aws contains code for working with AWS Services
package aws

import (

	"encoding/json"
)

// Resources list of type Resource
type Resources []Resource

// Resource represents a Physical Resource in AWS.
type Resource struct{
	Type string
	Properties map[string]interface{}
	APIDescription interface{}
}

func (r *Resource) Build(resource interface{}) (*Resource, error) {
	res, err := json.Marshal(resource)
	if err != nil {
		return nil, err
	}
	json.Unmarshal(res, r)
	return r, nil
}


