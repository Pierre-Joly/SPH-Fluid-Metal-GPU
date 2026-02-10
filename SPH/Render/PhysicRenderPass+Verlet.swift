import MetalKit

extension PhysicRenderPass {
    func runVerlet(encoder: MTLComputeCommandEncoder) {
        // Force at current state
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)

        encoder.setComputePipelineState(reorderPositionsVelocitiesPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.densityPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(reorderDensityPressurePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setBuffer(self.forceK1Buffer, offset: 0, index: ForceBuffer.index)
        encoder.setComputePipelineState(self.forcePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Advance positions, build half velocity - Step 1
        encoder.setComputePipelineState(self.verletStep1PSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Force at new positions (use half velocity for viscosity)
        encoder.setBuffer(self.positionBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityK1Buffer, offset: 0, index: VelocityBuffer.index)

        encoder.setComputePipelineState(reorderPositionsVelocitiesPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.densityPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(reorderDensityPressurePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setBuffer(self.forceK2Buffer, offset: 0, index: ForceBuffer.index)
        encoder.setComputePipelineState(self.forcePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Finalize velocity - Step 2
        encoder.setComputePipelineState(self.verletStep2PSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
    }
}
