 % dice(6,3,1000) will roll 3x6-sided die 10,000 times & graph it
function dice(faces, num_die, num_throws)
  if (nargin != 3)
    disp("die (faces, num_die, num_throws)");
  endif
  throws = sum(floor(rand(num_die,num_throws)*faces+1));
   % hist()'s 2nd argument can be an array
   % 3 x 6-sided die, that would work out to 3:(3*6) = 3:18 = 3 4 5 ... 17 18
  hist(throws, num_die:(num_die*faces));
endfunction
