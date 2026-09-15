function node=makeScatter3Series()
%MAKESCATTER3SERIES Rich scatter roles with explicit Cartesian Z coordinates.
    node=m2t2.ir.makeScatterSeries();node.kind='m2t2.scatter3';node.z=zeros(1,0);
end
