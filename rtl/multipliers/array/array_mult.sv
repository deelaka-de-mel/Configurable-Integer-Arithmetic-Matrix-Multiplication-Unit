module array_mult#(
	parameter int N=4
	)(
		input logic [N-1:0] a,
		input logic [N-1:0] b,
		output logic [2*N-1:0] result);
		
		logic wi1,wi2,wi3;
		logic xi1,xi2,xi3,xi4, xc1,xc2,xc3,xc4,xs1,xs2,xs3;
		logic yi1,yi2,yi3,yi4,yc1,yc2,yc3,yc4,ys1,ys2,ys3;
		logic zi1,zi2,zi3,zi4,zc1,zc2,zc3;
		
		
		assign result[0] = a[0] & b[0];
		
		assign wi1 = a[1] & b[0];
		assign wi2 = a[2] & b[0];
		assign wi3 = a[3] & b[0];
		
		assign xi1 = a[0] & b[1];
		assign xi2 = a[1] & b[1];
		assign xi3 = a[2] & b[1];
		assign xi4 = a[3] & b[1];
		 
		
		FullAdder fa0 (
					.x(xi1),
					.y(wi1),
					.ci(0),
					.sum(result[1]),
					.co(xc1)
					);
		
		FullAdder fa1 (
					.x(xi2),
					.y(wi2),
					.ci(xc1),
					.sum(xs1),
					.co(xc2)
					);
					
		FullAdder fa2 (
					.x(xi3),
					.y(wi3),
					.ci(xc2),
					.sum(xs2),
					.co(xc3)
					);
					
		FullAdder fa3 (
					.x(xi4),
					.y(0),
					.ci(xc3),
					.sum(xs3),
					.co(xc4)
					);
					
		assign yi1 = a[0] & b[2];
		assign yi2 = a[1] & b[2];
		assign yi3 = a[2] & b[2];
		assign yi4 = a[3] & b[2];
		 
					
		FullAdder fa4 (
					.x(yi1),
					.y(xs1),
					.ci(0),
					.sum(result[2]),
					.co(yc1)
					);
					
		FullAdder fa5 (
					.x(yi2),
					.y(xs2),
					.ci(yc1),
					.sum(ys1),
					.co(yc2)
					);
					
		FullAdder fa6 (
					.x(yi3),
					.y(xs3),
					.ci(yc2),
					.sum(ys2),
					.co(yc3)
					);
					
		FullAdder fa7 (
					.x(yi4),
					.y(xc4),
					.ci(yc3),
					.sum(ys3),
					.co(yc4)
					);
		
		assign zi1 = a[0] & b[3];
		assign zi2 = a[1] & b[3];
		assign zi3 = a[2] & b[3];
		assign zi4 = a[3] & b[3];
		
		FullAdder fa8 (
					.x(ys1),
					.y(zi1),
					.ci(0),
					.sum(result[3]),
					.co(zc1)
					);
					
		FullAdder fa9 (
					.x(ys2),
					.y(zi2),
					.ci(zc1),
					.sum(result[4]),
					.co(zc2)
					);
					
		FullAdder fa10 (
					.x(ys3),
					.y(zi3),
					.ci(zc2),
					.sum(result[5]),
					.co(zc3)
					);
					
		FullAdder fa11 (
					.x(yc4),
					.y(zi4),
					.ci(zc3),
					.sum(result[6]),
					.co(result[7])
					);
					
endmodule		