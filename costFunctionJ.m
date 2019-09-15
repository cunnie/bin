function J = costFunctionJ(X, y, theta)
  % X is the "design matrix" containing our training exaples
  % y is the class labels

  % Test
  % X = [1 1; 1 2; 1 3]
  % y = [1; 2; 3]
  % theta = [0; 1]
  % ans = 0

  m = length(X); % number of training examples
  predictions = X*theta; % predictions of hypothesis on all m examples
  sqrErrors = (predictions-y).^2; % squared errors

  J = 1/(2*m) * sum(sqrErrors);
end
