package BOKUTIN::Email::Find::Loose;
use base qw(Email::Find);
use Email::Valid::Loose;

# should return regex, which Email::Find will use in finding
# strings which are "thought to be" email addresses
sub addr_regex {
    return $Email::Valid::Loose::Addr_spec_re;
}

# should validate $addr is a valid email or not.
# if so, return the address as a string.
# else, return undef
sub do_validate {
    my($self, $addr) = @_;
    return Email::Valid::Loose->address($addr);
}

1;
