# -*- encoding: utf-8

import os
import pytest


@pytest.fixture
def hostname():
    host = os.environ.get('HOSTNAME', 'localhost')
    port = os.environ.get('PORT', 5757)
    return '%s:%s' % (host, port)


@pytest.fixture
def baseurl(hostname):
    return 'http://%s/' % hostname
