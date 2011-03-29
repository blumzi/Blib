#!/bin/bash

#
# Dummy function, for tags(1)
#
function const() {
	:
}
               const_default_IFS=$'\x20'$'\x09'$'\x0A'$'\x0D'
#
# Well known sizes
#
                        const_kb=1024
                        const_mb=$(( ${const_kb} * ${const_kb} ))
                        const_gb=$(( ${const_mb} * ${const_kb} ))

#
# Display constants
#
 const_keyword_text_is_set="<is-set>"
const_keyword_text_not_set="<not-set>"
   const_keyword_text_none="<none>"

  const_keyword_xml_is_set=""
 const_keyword_xml_not_set=""
    const_keyword_xml_none=""

  const_multival_separator=$'\xf3'
    const_blocked_selector=$'\xf5'

#
# Bash special characters for str_escape and str_unescape
#
          const_space=$'\x20'
            const_tab=$'\x09'
          const_quote=$'\x27'
         const_dquote=$'\x22'
         const_bquote=$'\x60'
        const_newline=$'\x0a'
         const_dollar=$'\x24'
           const_lpar=$'\x28'
           const_rpar=$'\x29'
          const_lbrkt=$'\x5b'
          const_rbrkt=$'\x5d'
         const_lsharp=$'\x3c'
         const_rsharp=$'\x3e'

    const_escaped_tab=$'\xfa'
  const_escaped_quote=$'\xfb'
 const_escaped_dquote=$'\xfc'
 const_escaped_bquote=$'\xfd'
  const_escaped_space=$'\xfe'
const_escaped_newline=$'\xf9'
 const_escaped_dollar=$'\xf8'
   const_escaped_lpar=$'\xf7'
   const_escaped_rpar=$'\xf6'
  const_escaped_lbrkt=$'\xf5'
  const_escaped_rbrkt=$'\xf4'
 const_escaped_lsharp=$'\xf3'
 const_escaped_rsharp=$'\xf2'

const_keyword_not_available="not-available"

       const_press_enter="Press <Enter> to continue"
    const_invalid_choice="Invalid choice"

#
# Input hints
#
const_input_hint_forced_password="6-8 letters, digits or '_'"
       const_input_hint_password="6-8 letters, digits or '_', or \"${const_password_no_change}\""
         const_input_hint_yes_no="y/n"
     const_input_hint_identifier="a letter then digits, letters or _"
         const_input_hint_ipaddr="IP address" 
         const_input_hint_ipmask="IP mask" 
		 const_input_hint_port="1-65355"
  const_input_hint_listener_type="TCP/UDP"

#
# Warnings handling:
#  When a sub-process exits but we want to ignore it, we add 200 to the
#  original exit status.  The number 200 was chosen because the shell uses
#  the following conventions for exit status values:
#
#  0:     success exit status
#  1-125: failure exit status.  NOTE: a well behaved command should not exit with a higher status
#  126:   command-found but not executable
#  127:   command-not-found exit status
#  128+n: process exited on signal n ( 1 <= n <= 64 )
#
          const_status_warning=200	# warning exit status

#
# traces
#
         const_trace_sep=$'\xef'
const_trace_internal_sep=$'\xee'
