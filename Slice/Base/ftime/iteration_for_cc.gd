class_name Find_Time_Iteration_For_CC

const Iteration = Find_Time_Iteration.Iteration


class Iteration_For_CC \
extends Iteration:

	var mass0 := INT64_MAX


	func calculate_aberration (base: Base) -> int:
		var aberration := 0
		for time_i in range(1, params.time_div+1):
			aberration += abs(mass0 - calculate_mass(base, time_i))
		return aberration
