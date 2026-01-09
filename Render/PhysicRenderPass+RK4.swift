import MetalKit

extension PhysicRenderPass {
    func runRK4(encoder: MTLComputeCommandEncoder) {
        // Runge Kutta 4 - Step 1
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

        encoder.setComputePipelineState(rk4Step1PSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Runge Kutta 4 - Step 2
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionBuffer.index)
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

        encoder.setComputePipelineState(self.rk4Step2PSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Runge Kutta 4 - Step 3
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityK2Buffer, offset: 0, index: VelocityBuffer.index)

        encoder.setComputePipelineState(reorderPositionsVelocitiesPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.densityPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(reorderDensityPressurePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setBuffer(self.forceK3Buffer, offset: 0, index: ForceBuffer.index)
        encoder.setComputePipelineState(self.forcePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.rk4Step3PSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Runge Kutta 4 - Step 4
        encoder.setBuffer(self.positionKBuffer, offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityK3Buffer, offset: 0, index: VelocityBuffer.index)

        encoder.setComputePipelineState(reorderPositionsVelocitiesPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.densityPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(reorderDensityPressurePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setBuffer(self.forceK4Buffer, offset: 0, index: ForceBuffer.index)
        encoder.setComputePipelineState(self.forcePSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        // Final integration
        encoder.setBuffer(self.positionBuffer,  offset: 0, index: PositionBuffer.index)
        encoder.setBuffer(self.velocityBuffer, offset: 0, index: VelocityBuffer.index)
        encoder.setComputePipelineState(self.rk4FinalPSO)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
    }
}
