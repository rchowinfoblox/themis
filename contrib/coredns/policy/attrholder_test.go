package policy

import (
	"testing"

	pdp "github.com/infobloxopen/themis/pdp-service"
)

func TestActionFromResponse(t *testing.T) {
	tests := []struct {
		resp     *pdp.Response
		action   int
		redirect string
	}{
		{
			resp:     &pdp.Response{Effect: pdp.Response_PERMIT},
			action:   typeAllow,
			redirect: "",
		},
		{
			resp:     &pdp.Response{Effect: pdp.Response_INDETERMINATE},
			action:   typeInvalid,
			redirect: "",
		},
		{
			resp:     &pdp.Response{Effect: pdp.Response_DENY},
			action:   typeBlock,
			redirect: "",
		},
		{
			resp: &pdp.Response{Effect: pdp.Response_DENY, Obligation: []*pdp.Attribute{
				{Id: "redirect_to", Value: "10.10.10.10"},
			}},
			action:   typeRedirect,
			redirect: "10.10.10.10",
		},
		{
			resp: &pdp.Response{Effect: pdp.Response_DENY, Obligation: []*pdp.Attribute{
				{Id: "refuse", Value: "true"},
			}},
			action:   typeRefuse,
			redirect: "",
		},
		{
			resp: &pdp.Response{Effect: pdp.Response_PERMIT, Obligation: []*pdp.Attribute{
				{Id: "log", Value: ""},
			}},
			action:   typeLog,
			redirect: "",
		},
	}

	for i, test := range tests {
		ah := newAttrHolder("test.com", 1)
		ah.addResponse(test.resp)
		if ah.action != test.action {
			t.Errorf("Unexpected action in TC #%d: expected=%d, actual=%d", i, test.action, ah.action)
		}
		strR := ""
		if ah.redirect != nil {
			strR = ah.redirect.GetValue()
		}
		if strR != test.redirect {
			t.Errorf("Unexpected redirect in TC #%d: expected=%q, actual=%q", i, test.redirect, strR)
		}
	}
}

func TestNilResponse(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("addResponse() did not panic for nil response")
		}
	}()

	ah := newAttrHolder("test.com", 1)
	ah.addResponse(nil)
}

func TestAllowActionAfterLogAction(t *testing.T) {
	ah := newAttrHolder("test.com", 1)
	ah.addResponse(&pdp.Response{Effect: pdp.Response_PERMIT, Obligation: []*pdp.Attribute{
		{Id: "log"},
	}})
	ah.addResponse(&pdp.Response{Effect: pdp.Response_PERMIT})
	if ah.action != typeLog {
		t.Errorf("Unexpected action: expected=%d, actual=%d", typeLog, ah.action)
	}
}
