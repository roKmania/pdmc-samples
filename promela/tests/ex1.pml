	int state = 2;

	proctype A()
	{	(state == 1) ; state = 3
	}

	proctype B()
	{	state = state - 1
	}

	proctype C(int mystate; int foo)
	{
		(mystate == 1) ; mystate = foo
	}

	init
	{	run A(); run B()
	}
